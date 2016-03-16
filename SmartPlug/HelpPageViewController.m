//
//  HelpPageViewController.m
//  SmartPlug
//
//  Created by Kevin Phua on 03/16/16.
//  Copyright © 2016 hagarsoft. All rights reserved.
//

#import "HelpPageViewController.h"
#import "HelpViewController.h"

#define NUM_PAGES   7

@interface HelpPageViewController ()

@property (strong, nonatomic) UIPageViewController *pageController;
@property (strong, nonatomic) NSArray *viewControllers;
@property (nonatomic) NSInteger currentPage;

@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;

@end

@implementation HelpPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    self.pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    
    self.pageController.dataSource = self;
    self.pageController.delegate = self;
    [self.pageController.view setFrame:self.view.bounds];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [self.pageController willMoveToParentViewController:self];
    
    [self addChildViewController:self.pageController];
    
    [self.view addSubview:self.pageController.view];
    
    [self.pageController didMoveToParentViewController:self];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    HelpViewController *viewControllerObject = (HelpViewController *)[self viewControllerAtIndex:self.startIndex];
    self.viewControllers = [NSArray arrayWithObject:viewControllerObject];
    
    [self.pageController setViewControllers:self.viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    self.pageControl.numberOfPages = NUM_PAGES;
    self.pageControl.currentPage = self.startIndex;
    [self.view bringSubviewToFront:self.pageControl];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    
    if (viewController == nil) {
        return [self viewControllerAtIndex:0];
    }
    
    NSUInteger index = [(HelpViewController *)viewController indexNumber];
    if (index <= 0) {
        return nil;
    }

    index--;
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    
    NSUInteger index = [(HelpViewController *)viewController indexNumber];
    if (index >= NUM_PAGES-1) {
        return nil;
    }

    index++;
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)viewControllerAtIndex:(NSUInteger)index {
    HelpViewController *childViewController = [HelpViewController new];
    childViewController.indexNumber = index;
    self.currentPage = index;
    return childViewController;
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    if (completed) {
        HelpViewController *vc = (HelpViewController *)[self.pageController.viewControllers lastObject];
        NSInteger currentIndex = vc.indexNumber;
        self.pageControl.currentPage = currentIndex;
    }
}

@end
