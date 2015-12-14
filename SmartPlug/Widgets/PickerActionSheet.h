//
//  PickerActionSheet.h
//  SpaceMonitor
//
//  Created by Chin-Yu Hsu on 8/31/12.
//
//

#import <UIKit/UIKit.h>

@protocol PickerActionSheetDelegate;

@interface PickerActionSheet : NSObject

@property (strong, nonatomic) UIDatePicker* datePicker;
@property (nonatomic, assign) id <PickerActionSheetDelegate> delegate;

- (PickerActionSheet *) initWithTitle : (NSString *)title delegate:(id<PickerActionSheetDelegate>)asd pickerDelegate:(id<UIPickerViewDelegate>)pd currRow : (int)currRow;
- (PickerActionSheet *) initWithTitle : (NSString *)title delegate:(id<PickerActionSheetDelegate>)asd SelDate:(NSDate*)selDate;
- (void) showInView : ( UIView *)view;

- (NSInteger)selectedRow;
- (NSInteger)preSelectedRow;
@end


@protocol PickerActionSheetDelegate <NSObject>

@optional
- (void)actionSheet:(PickerActionSheet *)sheet clickedButtonAtIndex:(NSInteger)buttonIndex;

@end