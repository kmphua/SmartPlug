//
//  IRListCommandsViewController.m
//  SmartPlug
//
//  Created by Kevin Phua on 5/16/16.
//  Copyright © 2016 Kevin Phua. All rights reserved.
//

#import "IRListCommandsViewController.h"
#import "SLExpandableTableView.h"

@interface IRListCommandsViewController () <SLExpandableTableViewDatasource, SLExpandableTableViewDelegate>

@property (nonatomic, strong) NSMutableArray *irGroups;
@property (nonatomic, strong) NSMutableDictionary *irCodes;

@end

@interface SLExpandableTableViewControllerHeaderCell : UITableViewCell <UIExpandingTableViewCell>

@property (nonatomic, assign, getter = isLoading) BOOL loading;

@property (nonatomic, readonly) UIExpansionStyle expansionStyle;
- (void)setExpansionStyle:(UIExpansionStyle)expansionStyle animated:(BOOL)animated;

@end

@implementation SLExpandableTableViewControllerHeaderCell

- (NSString *)accessibilityLabel
{
    return self.textLabel.text;
}

- (void)setLoading:(BOOL)loading
{
    if (loading != _loading) {
        _loading = loading;
        [self _updateDetailTextLabel];
    }
}

- (void)setExpansionStyle:(UIExpansionStyle)expansionStyle animated:(BOOL)animated
{
    if (expansionStyle != _expansionStyle) {
        _expansionStyle = expansionStyle;
        [self _updateDetailTextLabel];
    }
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self _updateDetailTextLabel];
        self.backgroundColor = [UIColor yellowColor];
    }
    return self;
}

- (void)_updateDetailTextLabel
{
    if (self.isLoading) {
        self.detailTextLabel.text = @"Loading data";
    } else {
        switch (self.expansionStyle) {
            case UIExpansionStyleExpanded:
                self.detailTextLabel.text = @"-";
                break;
            case UIExpansionStyleCollapsed:
                self.detailTextLabel.text = @"+";
                break;
        }
    }
}

@end


@implementation IRListCommandsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    _irGroups = [NSMutableArray new];
    _irCodes = [NSMutableDictionary new];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [_irGroups removeAllObjects];
    [_irCodes removeAllObjects];
    NSArray *groups = [[SQLHelper getInstance] getIRGroupByMac:g_DeviceMac];
    for (IrGroup *group in groups) {
        NSString *groupName = group.name;
        [_irGroups addObject:group.name];
        NSMutableArray *codeList = [NSMutableArray new];
        NSArray *codes = [[SQLHelper getInstance] getIRCodesByGroup:group.group_id];
        for (IrCode *code in codes) {
            [codeList addObject:[code copy]];
        }
        [_irCodes setObject:codes forKey:groupName];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadView
{
    SLExpandableTableView *tableView = [[SLExpandableTableView alloc] initWithFrame:[UIScreen mainScreen].bounds style:UITableViewStylePlain];
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view = tableView;
}

//==================================================================
#pragma mark - UITableViewDelegate
//==================================================================

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return _irGroups.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString *groupName = [_irGroups objectAtIndex:section];
    NSArray *codes = [_irCodes objectForKey:groupName];
    return codes.count + 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 72;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TableViewCell";
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
    NSString *groupName = [_irGroups objectAtIndex:indexPath.section];
    NSArray *codes = [_irCodes objectForKey:groupName];
    IrCode *code = [codes objectAtIndex:indexPath.row-1];
    cell.textLabel.text = code.name;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.delegate) {
        NSString *groupName = [_irGroups objectAtIndex:indexPath.section];
        NSArray *codes = [_irCodes objectForKey:groupName];
        IrCode *code = [codes objectAtIndex:indexPath.row];
        [self.delegate onSelectIRCommand:_status group:groupName irName:code.name];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

//==================================================================
#pragma mark - SLExpandableTableViewDatasource
//==================================================================

- (BOOL)tableView:(SLExpandableTableView *)tableView canExpandSection:(NSInteger)section
{
    return YES;
}

- (BOOL)tableView:(SLExpandableTableView *)tableView needsToDownloadDataForExpandableSection:(NSInteger)section
{
    return NO;
}

- (UITableViewCell<UIExpandingTableViewCell> *)tableView:(SLExpandableTableView *)tableView expandingCellForSection:(NSInteger)section
{
    static NSString *CellIdentifier = @"SLExpandableTableViewControllerHeaderCell";
    SLExpandableTableViewControllerHeaderCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[SLExpandableTableViewControllerHeaderCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    NSString *groupName = [_irGroups objectAtIndex:section];
    cell.textLabel.text = groupName;
    return cell;
}

//==================================================================
#pragma mark - SLExpandableTableViewDelegate
//==================================================================

- (void)tableView:(SLExpandableTableView *)tableView downloadDataForExpandableSection:(NSInteger)section
{
    // download your data here
    // call [tableView expandSection:section animated:YES]; if download was successful
    // call [tableView cancelDownloadInSection:section]; if your download was NOT successful
}

- (void)tableView:(SLExpandableTableView *)tableView didExpandSection:(NSUInteger)section animated:(BOOL)animated
{
    //...
}

- (void)tableView:(SLExpandableTableView *)tableView didCollapseSection:(NSUInteger)section animated:(BOOL)animated
{
    //...
}

@end
