#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <substrate.h>

typedef BOOL (*CLTShouldHighlightIMP)(id, SEL, UITableView *, NSIndexPath *);
typedef NSIndexPath *(*CLTWillSelectIMP)(id, SEL, UITableView *, NSIndexPath *);
typedef void (*CLTDidSelectIMP)(id, SEL, UITableView *, NSIndexPath *);

typedef struct {
    Class cls;
    BOOL installed;
    CLTShouldHighlightIMP originalShouldHighlight;
    CLTWillSelectIMP originalWillSelect;
    CLTDidSelectIMP originalDidSelect;
} CLTDelegateHooks;

static CLTDelegateHooks gAboutControllerHooks;
static CLTDelegateHooks gAboutDataSourceHooks;

// Returns the GeneralSettingsUI framework bundle once it is loaded. The
// Carrier Lock row lives in its "General" localization table, and the table
// already ships Apple's own "No SIM restrictions" string, so the tweak can
// reuse it instead of hardcoding a translation.
static NSBundle *CLTGeneralSettingsBundle(void) {
    static NSBundle *bundle;

    if (bundle == nil) {
        for (NSBundle *candidate in [NSBundle allFrameworks]) {
            if ([candidate.bundlePath containsString:@"GeneralSettingsUI.framework"]) {
                bundle = candidate;
                break;
            }
        }
    }

    return bundle;
}

// Apple's localized "No SIM restrictions" text for the current system
// language. Nil when the framework bundle is not loaded yet.
static NSString *CLTUnlockedText(void) {
    NSBundle *bundle = CLTGeneralSettingsBundle();
    if (bundle == nil) {
        return nil;
    }

    return [bundle localizedStringForKey:@"CARRIER_LOCK_UNLOCKED"
                                   value:nil
                                   table:@"General"];
}

static BOOL CLTIsCarrierLockCell(UITableViewCell *cell) {
    if (cell == nil) {
        return NO;
    }

    NSString *detail = cell.detailTextLabel.text;

    if (@available(iOS 14.0, *)) {
        UIListContentConfiguration *content =
            [cell.contentConfiguration isKindOfClass:UIListContentConfiguration.class]
                ? (UIListContentConfiguration *)cell.contentConfiguration
                : nil;

        detail = detail ?: content.secondaryText;
    }

    NSString *unlocked = CLTUnlockedText();
    return unlocked != nil && [detail isEqualToString:unlocked];
}

static BOOL CLTIsCarrierLockRow(UITableView *tableView, NSIndexPath *indexPath) {
    return indexPath != nil &&
           CLTIsCarrierLockCell([tableView cellForRowAtIndexPath:indexPath]);
}

static CLTDelegateHooks *CLTHooksForClass(Class cls) {
    if (cls == Nil) {
        return NULL;
    }

    const char *className = class_getName(cls);

    if (strcmp(className, "PSGAboutController") == 0) {
        return &gAboutControllerHooks;
    }

    if (strcmp(className, "PSGAboutDataSource") == 0) {
        return &gAboutDataSourceHooks;
    }

    return NULL;
}

static CLTDelegateHooks *CLTHooksForObject(id object) {
    return CLTHooksForClass(object_getClass(object));
}

static BOOL CLTShouldHighlight(id self, SEL _cmd, UITableView *tableView,
                               NSIndexPath *indexPath) {
    if (CLTIsCarrierLockRow(tableView, indexPath)) {
        return NO;
    }

    CLTDelegateHooks *hooks = CLTHooksForObject(self);
    return hooks != NULL && hooks->originalShouldHighlight != NULL
               ? hooks->originalShouldHighlight(self, _cmd, tableView, indexPath)
               : YES;
}

static NSIndexPath *CLTWillSelect(id self, SEL _cmd, UITableView *tableView,
                                  NSIndexPath *indexPath) {
    if (CLTIsCarrierLockRow(tableView, indexPath)) {
        return nil;
    }

    CLTDelegateHooks *hooks = CLTHooksForObject(self);
    return hooks != NULL && hooks->originalWillSelect != NULL
               ? hooks->originalWillSelect(self, _cmd, tableView, indexPath)
               : indexPath;
}

static void CLTDidSelect(id self, SEL _cmd, UITableView *tableView,
                         NSIndexPath *indexPath) {
    if (CLTIsCarrierLockRow(tableView, indexPath)) {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        return;
    }

    CLTDelegateHooks *hooks = CLTHooksForObject(self);
    if (hooks != NULL && hooks->originalDidSelect != NULL) {
        hooks->originalDidSelect(self, _cmd, tableView, indexPath);
    }
}

static void CLTInstallSelectionHooks(id delegate) {
    Class cls = object_getClass(delegate);
    CLTDelegateHooks *hooks = CLTHooksForClass(cls);

    if (hooks == NULL || hooks->installed) {
        return;
    }

    hooks->cls = cls;
    hooks->installed = YES;

    SEL shouldHighlight = @selector(tableView:shouldHighlightRowAtIndexPath:);
    Method shouldHighlightMethod = class_getInstanceMethod(cls, shouldHighlight);
    if (shouldHighlightMethod != NULL) {
        MSHookMessageEx(cls, shouldHighlight, (IMP)CLTShouldHighlight,
                        (IMP *)&hooks->originalShouldHighlight);
    } else {
        class_addMethod(cls, shouldHighlight, (IMP)CLTShouldHighlight, "B@:@@");
    }

    SEL willSelect = @selector(tableView:willSelectRowAtIndexPath:);
    Method willSelectMethod = class_getInstanceMethod(cls, willSelect);
    if (willSelectMethod != NULL) {
        MSHookMessageEx(cls, willSelect, (IMP)CLTWillSelect,
                        (IMP *)&hooks->originalWillSelect);
    } else {
        class_addMethod(cls, willSelect, (IMP)CLTWillSelect, "@@:@@");
    }

    SEL didSelect = @selector(tableView:didSelectRowAtIndexPath:);
    Method didSelectMethod = class_getInstanceMethod(cls, didSelect);
    if (didSelectMethod != NULL) {
        MSHookMessageEx(cls, didSelect, (IMP)CLTDidSelect,
                        (IMP *)&hooks->originalDidSelect);
    }
}

%hook NSBundle

- (NSString *)localizedStringForKey:(NSString *)key
                              value:(NSString *)value
                              table:(NSString *)tableName {
    NSString *bundlePath = self.bundlePath;

    BOOL isTargetTable = [tableName isEqualToString:@"General"];
    BOOL isTargetBundle = [bundlePath containsString:@"GeneralSettingsUI.framework"];

    if (isTargetTable && isTargetBundle) {
        // Reuse Apple's own localized unlocked strings so the text follows
        // the current system language instead of a hardcoded translation.
        if ([key isEqualToString:@"CARRIER_LOCK_LOCKED"]) {
            NSString *unlocked = %orig(@"CARRIER_LOCK_UNLOCKED", nil, tableName);
            return unlocked != nil ? unlocked : %orig;
        }

        if ([key isEqualToString:@"CARRIER_LOCK_LOCKED_DETAILS"]) {
            NSString *unlockedDetails = %orig(@"CARRIER_LOCK_UNLOCKED_DETAILS", nil, tableName);
            if (unlockedDetails != nil) {
                return unlockedDetails;
            }

            NSString *unlocked = %orig(@"CARRIER_LOCK_UNLOCKED", nil, tableName);
            return unlocked != nil ? unlocked : %orig;
        }
    }

    return %orig;
}

%end

%hook UITableView

- (void)setDelegate:(id<UITableViewDelegate>)delegate {
    CLTInstallSelectionHooks(delegate);
    %orig;
}

%end

%hook UIViewController

- (void)viewDidLoad {
    %orig;
    CLTInstallSelectionHooks(self);
}

%end

%hook UITableViewCell

- (void)layoutSubviews {
    %orig;

    if (CLTIsCarrierLockCell(self)) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.accessoryType = UITableViewCellAccessoryNone;
    }
}

%end
