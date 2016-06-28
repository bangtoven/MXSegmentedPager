// MXSegmentedPagerController.m
//
// Copyright (c) 2016 Maxime Epain
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "MXSegmentedPagerController.h"

#pragma mark - UIScrollView extension

@interface UIScrollView (UpdateEdgeInset)
- (void)updateEdgeInsetWithBottom:(CGFloat)bottom;
@end

@implementation UIScrollView (UpdateEdgeInset)
- (UIEdgeInsets)updatedEdgeInset:(UIEdgeInsets)inset withBottom:(CGFloat)bottom {
    return UIEdgeInsetsMake(inset.top, inset.left, bottom, inset.right);
}
- (void)updateEdgeInsetWithBottom:(CGFloat)bottom {
    self.contentInset = [self updatedEdgeInset:self.contentInset withBottom:bottom];
    self.scrollIndicatorInsets = [self updatedEdgeInset:self.scrollIndicatorInsets withBottom:bottom];
}
@end

#pragma mark - MXSegmentedPagerController

@interface MXSegmentedPagerController () <MXPageSegueDelegate>

@end

@implementation MXSegmentedPagerController {
    UIViewController *_pageViewController;
    NSInteger _pageIndex;
}

@synthesize segmentedPager = _segmentedPager;

- (void)loadView {
    self.view = self.segmentedPager;
}

#pragma mark Properties

- (UIView *)segmentedPager {
    if (!_segmentedPager) {
        _segmentedPager = [[MXSegmentedPager alloc] init];
        _segmentedPager.delegate    = self;
        _segmentedPager.dataSource  = self;
    }
    return _segmentedPager;
}

#pragma mark <MXSegmentedPagerControllerDataSource>

- (NSInteger)numberOfPagesInSegmentedPager:(MXSegmentedPager *)segmentedPager {
    NSInteger count = 0;
    
    //Hack to get number of MXPageSegue
    NSArray *templates = [self valueForKey:@"storyboardSegueTemplates"];
    for (id template in templates) {
        NSString *segueClasseName = [template valueForKey:@"_segueClassName"];
        if ([segueClasseName isEqualToString:NSStringFromClass(MXPageSegue.class)]) {
            count++;
        }
    }
    return count;
}

- (UIView *)segmentedPager:(MXSegmentedPager *)segmentedPager viewForPageAtIndex:(NSInteger)index {
    
    UIViewController *viewController = [self segmentedPager:segmentedPager viewControllerForPageAtIndex:index];
    
    if (viewController) {
        [self addChildViewController:viewController];
        [viewController didMoveToParentViewController:self];

        UIView *view = viewController.view;
        
        CGFloat barHeight = 0;
        barHeight += CGRectGetHeight(self.tabBarController.tabBar.frame);
        if (self.navigationController.toolbarHidden == NO) {
            barHeight += CGRectGetHeight(self.navigationController.toolbar.frame);
        }
        
        if ((self.edgesForExtendedLayout & UIRectEdgeBottom) && (barHeight > 0)) {
            if ([view isKindOfClass:[UIScrollView class]]) {
                UIScrollView *scrollView = (UIScrollView*)view;
                [scrollView updateEdgeInsetWithBottom: barHeight];
            } else {
                for (UIView* subView in view.subviews) {
                    UIScrollView *scrollView;
                    if ([subView isKindOfClass:[UIScrollView class]]) {
                        scrollView = (UIScrollView*)subView;
                    } else if ([subView isKindOfClass:[UIWebView class]]) {
                        scrollView = ((UIWebView*)subView).scrollView;
                    }
                    
                    if (scrollView != nil) {
                        if (true) { // need to check the bottom layout constraint between view and subView.
                            [scrollView updateEdgeInsetWithBottom: barHeight];
                        } else {
                            CGRect barFrame = CGRectMake(0, CGRectGetHeight(self.view.frame) - barHeight, CGRectGetHeight(self.view.frame), barHeight);
                            CGRect intersect = CGRectIntersection(scrollView.frame, barFrame);
                            CGFloat intersectHeight = CGRectGetHeight(intersect);
                            [scrollView updateEdgeInsetWithBottom: intersectHeight];
                        }
                    }
                }
            }
        }
        
        return view;
    }
    return nil;
}

- (UIViewController *)segmentedPager:(MXSegmentedPager *)segmentedPager viewControllerForPageAtIndex:(NSInteger)index {
    if (self.storyboard) {
        @try {
            NSString *identifier = [self segmentedPager:segmentedPager segueIdentifierForPageAtIndex:index];
            _pageIndex = index;
            [self performSegueWithIdentifier:identifier sender:nil];
            return _pageViewController;
        }
        @catch(NSException *exception) {}
    }
    return nil;
}

- (NSString *)segmentedPager:(MXSegmentedPager *)segmentedPager segueIdentifierForPageAtIndex:(NSInteger)index {
    return [NSString stringWithFormat:MXSeguePageIdentifierFormat, (long)index];
}

#pragma mark <MXPageSegueDelegate>

- (NSInteger)pageIndex {
    return _pageIndex;
}

- (void)setPageViewController:(UIViewController *)pageViewController {
    _pageViewController = pageViewController;
}

@end
