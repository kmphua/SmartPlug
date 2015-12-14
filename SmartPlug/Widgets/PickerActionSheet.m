//
//  PickerActionSheet.m
//  SpaceMonitor
//
//  Created by Chin-Yu Hsu on 8/31/12.
//
//

#import "PickerActionSheet.h"

#pragma mark -
#pragma mark MyAlertController implementation

@interface MyGreyBackgroundWindow : UIWindow {
    UIView *_view;
}

@property (nonatomic, weak) id<UIPopoverControllerDelegate> delegate;

@end

@implementation MyGreyBackgroundWindow

-(instancetype) init {
    self = [super initWithFrame:[UIScreen mainScreen].bounds];
    if( self ) {
        self.windowLevel = UIWindowLevelAlert;
        self.rootViewController = [UIViewController new];
        self.rootViewController.view.backgroundColor = [UIColor clearColor];
        _view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 250)];
        _view.backgroundColor = [UIColor whiteColor];
        [self.rootViewController.view addSubview:_view];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotate:) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
    }
    
    return self;
}

@synthesize delegate;

-(UIView *) view {
    return _view;
}

- (void) didRotate:(NSNotification *)notification
{
    if( delegate && [delegate respondsToSelector:@selector(popoverControllerDidDismissPopover:)]) {
        [delegate popoverControllerDidDismissPopover:nil];
    }
    self.hidden = YES;
}

-(void) show {
    self.backgroundColor = [UIColor clearColor];
    self.hidden = NO;
    [self makeKeyAndVisible];

    _view.center = CGPointMake(self.center.x, CGRectGetHeight(self.frame) + _view.frame.size.height / 2 );
    CGFloat yFinal = CGRectGetHeight(self.frame) - _view.frame.size.height / 2;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        _view.center = CGPointMake(self.center.x, yFinal);
    }];
}

-(void) hide {
    self.backgroundColor = [UIColor clearColor];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.backgroundColor = [UIColor clearColor];
        _view.center = CGPointMake(self.center.x, CGRectGetHeight(self.frame) + _view.frame.size.height / 2 );
    } completion:^(BOOL finished) {
        [self resignKeyWindow];
        self.hidden = YES;
    }];
}

@end

#pragma mark -
#pragma mark PickerActionSheet implementation

@interface PickerActionSheet () <UIActionSheetDelegate, UIPopoverControllerDelegate> {
    int mCurrRow;
}

@end


@implementation PickerActionSheet {
	UIPickerView *pickerView;
    UIDatePicker *datePicker;
	UIPopoverController		*_popover;
	UIActionSheet			*_actionSheet;
    MyGreyBackgroundWindow  *_custom;
	int						offsetChild;
}

@synthesize datePicker;
@synthesize delegate;

- (UIView *) baseinitWithTitle : (NSString *)title delegate:(id<PickerActionSheetDelegate>)asd {
	self.delegate = asd;
	
	UIView *baseView;
	UINavigationBar *bar = nil;
	UINavigationItem *item;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		UIViewController *viewController = [[UIViewController alloc] initWithNibName:nil bundle:nil];
		UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 250)];
		viewController.view = view;
		viewController.title = title;
		
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];

		navController.navigationBar.barStyle = UIBarStyleBlack;
		
		// create popover
		_popover = [[UIPopoverController alloc] initWithContentViewController:navController];
		_popover.delegate = self;
		[_popover setPopoverContentSize:view.bounds.size];

		item = viewController.navigationItem;
		
		baseView = view;
		offsetChild = 0;
		
        _custom = nil;
		_actionSheet = nil;
	} else {
        if( ( [ [ [ UIDevice currentDevice ] systemVersion ] floatValue ] >= 8.0 ) ) {
            // create alert controller
            _custom = [[MyGreyBackgroundWindow alloc] init];
            if( _custom==nil )
                return nil;
            
            _custom.delegate = self;

            bar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 1, 320, 44)];
            bar.barStyle = UIBarStyleDefault;
            
            item = [[UINavigationItem alloc] initWithTitle:title];
            
            baseView = _custom.view;
            offsetChild = 44;
            
            _actionSheet = nil;
            _popover = nil;
        } else {
            // create actionsheet
            _actionSheet = [[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
            if( _actionSheet==nil )
                return nil;
            
            bar = [[UINavigationBar alloc] initWithFrame:CGRectMake(8, 0, 304, 44)];
            bar.barStyle = UIBarStyleDefault;
            
            item = [[UINavigationItem alloc] initWithTitle:title];
            
            baseView = _actionSheet;
            offsetChild = 44;
            
            _custom = nil;
            _popover = nil;
        }
	}
	
	// Add navigation bar items
	UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(onOK:)];
	UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(onCancel:)];
	
	item.leftBarButtonItem = leftButton;
	item.rightBarButtonItem = rightButton;
	item.hidesBackButton = YES;
	
	if( bar!=nil ) {
		[bar pushNavigationItem:item animated:NO];
		[baseView addSubview:bar];
	}

	return baseView;
}

- (PickerActionSheet *) initWithTitle : (NSString *)title delegate:(id<PickerActionSheetDelegate>)asd pickerDelegate:(id<UIPickerViewDelegate>)pd currRow : (int)currRow {
	self =  [self init];
	if( self==nil )
		return nil;
	
	UIView *parent = [self baseinitWithTitle:title delegate:asd];
	if( parent==nil )
		return nil;
	
    // Add the picker
    pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, offsetChild, 0, 0)];
	
    pickerView.delegate = pd;
    pickerView.showsSelectionIndicator = YES;    // note this is default to NO

	if (currRow < 0) {
        currRow = 0;
    }
    mCurrRow = currRow;
    
    NSAssert((currRow >= 0), @"Selected picker row should be >= 0");
    
    [pickerView selectRow:currRow inComponent:0 animated:YES];

    [parent addSubview:pickerView];
	
	return self;
}

// for DatePicker
- (PickerActionSheet *) initWithTitle : (NSString *)title delegate:(id<PickerActionSheetDelegate>)asd SelDate:(NSDate *)selDate{
	self =  [self init];
	if( self==nil )
		return nil;
	
	UIView *parent = [self baseinitWithTitle:title delegate:asd];
	if( parent==nil )
		return nil;
	
    // Add the picker
    datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, offsetChild, 0, 0)];
    datePicker.datePickerMode = UIDatePickerModeDate;
    if (selDate != nil) {
        datePicker.date = selDate;
    }
    
    [parent addSubview:datePicker];
	
	return self;
}

// helper for showInView (to obtain parent view controller)
- (UIViewController *) findParentViewController : (UIView *)view {
    id nextResponder = [view nextResponder];
    if ([nextResponder isKindOfClass:[UIViewController class]]) {
        return nextResponder;
    } else if ([nextResponder isKindOfClass:[UIView class]]) {
        return [self findParentViewController:nextResponder];
    } else {
        return nil;
    }
}

- (void) showInView : ( UIView *)view {
	if( _actionSheet!=nil ) {
		[_actionSheet showInView:view];
		
		UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOut:)];
		tap.cancelsTouchesInView = NO; // So that legit taps on the table bubble up to the tableview
		[_actionSheet.superview addGestureRecognizer:tap];
		
		[_actionSheet setBounds:CGRectMake(0,0,320,472)];
	} else if( _popover!=nil ) {
		[_popover presentPopoverFromRect:view.bounds inView:view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else if( _custom!=nil ) {
        [_custom show];
    }
}

-(void)tapOut:(UIGestureRecognizer *)gestureRecognizer {
    CGPoint p = [gestureRecognizer locationInView:_actionSheet];
    if (p.y < 0) { // They tapped outside
		[self dismiss:-1];
    }
}

-(void)onOK:(id)button {
	[self dismiss:0];
}

-(void)onCancel:(id)button {
	[self dismiss:-1];
}

-(void)dismiss : (NSInteger)buttonIndex {
	[self.delegate actionSheet:self clickedButtonAtIndex:buttonIndex];

	if( _actionSheet!=nil )
		[_actionSheet dismissWithClickedButtonIndex:_actionSheet.cancelButtonIndex animated:YES];
	else if( _popover !=nil ) {
		[_popover dismissPopoverAnimated:YES];
    } else if( _custom!=nil ) {
        [_custom hide];
    }
}

- (NSInteger)selectedRow {
	return [pickerView selectedRowInComponent:0];
}

- (NSInteger)preSelectedRow {
	return mCurrRow;
}

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)sheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	[self.delegate actionSheet:self clickedButtonAtIndex:buttonIndex];
}

#pragma mark - UIPopoverControllerDelegate
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
	[self.delegate actionSheet:self clickedButtonAtIndex:-1];
}

@end
