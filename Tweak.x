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

static BOOL CLTIsCarrierLockCell(UITableViewCell *cell) {
    if (cell == nil) {
        return NO;
    }

    NSString *title = cell.textLabel.text;
    NSString *detail = cell.detailTextLabel.text;

    if (@available(iOS 14.0, *)) {
        UIListContentConfiguration *content =
            [cell.contentConfiguration isKindOfClass:UIListContentConfiguration.class]
                ? (UIListContentConfiguration *)cell.contentConfiguration
                : nil;

        title = title ?: content.text;
        detail = detail ?: content.secondaryText;
    }

    return [title isEqualToString:@"Khóa mạng"] &&
           [detail isEqualToString:@"Không giới hạn SIM"];
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
        if ([key isEqualToString:@"CARRIER_LOCK_LOCKED"]) {
            return @"Không giới hạn SIM";
        }

        if ([key isEqualToString:@"CARRIER_LOCK_LOCKED_DETAILS"]) {
            return @"Thiết bị này không bị giới hạn SIM và có thể sử dụng với bất kỳ nhà cung cấp mạng nào.";
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
