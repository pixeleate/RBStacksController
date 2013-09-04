//
//  RBStacksController.m
//  RBStacksViewDemo
//
//  Created by Rob Booth on 8/23/13.
//  Copyright (c) 2013 Rob Booth. All rights reserved.
//

#import "RBStacksController.h"
#import <QuartzCore/QuartzCore.h>

@interface RBStacksController () <UIGestureRecognizerDelegate>

@end

@implementation RBStacksController

- (id)initWithRootViewController:(UIViewController *)rootViewController
{
	self = [super init];

	[self addChildViewController:rootViewController];
	rootViewController.view.frame = self.view.bounds;
	[self.view addSubview:rootViewController.view];

	return self;
}

#pragma mark - Implementation

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated withGestures:(BOOL)gestures
{
	// TODO: put all views below this one into correct position (i.e. full screen, not revealed)
	UIViewController *oldViewController = nil;
	if (self.childViewControllers.count > 0) {
		oldViewController = [self.childViewControllers lastObject];
	}
	
	UIViewController *newViewController = viewController;

	newViewController.view.frame = CGRectMake(self.view.bounds.size.width,
											  self.view.bounds.origin.y,
											  self.view.bounds.size.width,
											  self.view.bounds.size.height);

	if (gestures)
	{
		UIPanGestureRecognizer * pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
		pan.delegate = self;
		[newViewController.view addGestureRecognizer:pan];
	}

	[self addChildViewController:newViewController];

	[newViewController willMoveToParentViewController:self];
	[self.view addSubview:newViewController.view];

	[self addShadow:newViewController.view];

	[UIView animateWithDuration:(!animated || !oldViewController) ? 0 : 0.35f animations:^{

		newViewController.view.frame = self.view.bounds;

	} completion:^(BOOL finished) {

		[newViewController didMoveToParentViewController:self];
		
	}];
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
	[self pushViewController:viewController animated:animated withGestures:YES];
}

- (void)popViewController:(UIViewController *)viewController completion:(void(^)(BOOL finished))completionBlock
{
	[viewController willMoveToParentViewController:nil];

	[UIView animateWithDuration:0.35f animations:^{

		viewController.view.center = CGPointMake(viewController.view.center.x + self.view.bounds.size.width, viewController.view.center.y);

	} completion:^(BOOL finished) {

		[viewController.view removeFromSuperview];
		[viewController removeFromParentViewController];
		completionBlock(finished);

	}];
}

- (UIViewController *)popViewController
{
	UIViewController * viewController = nil;

	if (self.childViewControllers.count > 1) // Can't remove the root
	{
		viewController = [self.childViewControllers lastObject];
		[self popViewController:viewController completion:^(BOOL finished){}];
	}

	return viewController;
}

- (void)popViewController:(UIViewController *)viewController
{
	[self popViewController:viewController completion:^(BOOL finished){}];
}

- (void)reveal:(UIViewController *)viewController
{
	// TODO: Add gutter width as a variable somehow - non global
	for (int i = self.childViewControllers.count - 1; i > 0; i--)
	{
		UIViewController * vc = [self.childViewControllers objectAtIndex:i];

		if (vc == viewController || vc.view.frame.origin.x > 0)
		{
			CGFloat displayGutter = 20.0 * (self.childViewControllers.count - i);

			CGRect newFrame = CGRectMake(self.view.bounds.size.width - displayGutter, viewController.view.frame.origin.y, viewController.view.frame.size.width, viewController.view.frame.size.height);

			CGFloat duration = 0.0f;
			if (vc == viewController) duration = 0.35f;

			[UIView animateWithDuration:duration animations:^{ viewController.view.frame = newFrame; } completion:^(BOOL finished) {}];
		}
	}
}

- (void)unReveal:(UIViewController *)viewController completion:(void(^)(BOOL finished))completionBlock
{
	[UIView animateWithDuration:0.35f animations:^{

		viewController.view.frame = self.view.bounds;

	} completion:^(BOOL finished) {

		completionBlock(finished);

	}];
}

- (void)unReveal:(UIViewController *)viewController
{
	[self unReveal:viewController completion:^(BOOL finished){}];
}

#pragma mark - UI Helpers

- (void)addShadow:(UIView *)view
{
	UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRoundedRect:view.bounds cornerRadius:0.0f];
    view.layer.shadowPath = shadowPath.CGPath;
    view.layer.shadowColor = [UIColor blackColor].CGColor;
    view.layer.shadowRadius = 10.0f;
    view.layer.shadowOpacity = 0.75f;
	view.layer.shadowOffset = CGSizeZero;
    view.clipsToBounds = NO;
}

#pragma mark - Gestures

- (IBAction)handlePan:(UIPanGestureRecognizer *)recognizer
{
	CGPoint translation = [recognizer translationInView:recognizer.view];

	float newCenterX = recognizer.view.center.x + translation.x;
	UIView * superView = recognizer.view.superview;

	if (abs([recognizer velocityInView:recognizer.view].x) > 1000.0)
	{
		[self handleSwipe:recognizer];
		return;
	}

	if (newCenterX < superView.center.x) newCenterX = superView.center.x;

	recognizer.view.center = CGPointMake(newCenterX, recognizer.view.center.y);
	[recognizer setTranslation:CGPointMake(0, 0) inView:recognizer.view];
}

- (void)handleSwipe:(UIPanGestureRecognizer *)recognizer
{
	static BOOL swiping = NO;
	CGFloat speed = [recognizer velocityInView:recognizer.view].x;
	
	for (UIViewController * vc in self.childViewControllers)
	{
		if (vc.view == recognizer.view && !swiping)
		{
			swiping = YES;
			if (speed > 0)
			{
				[self popViewController:vc completion:^(BOOL finished) {
					swiping = NO;
				}];
			}
			else
			{
				[self unReveal:vc completion:^(BOOL finished) {
					swiping = NO;
				}];
			}
		}
	}
}

#pragma mark - UIGestureRecognizer Delegate

// Do I need anything here?


@end

#pragma mark - Segues

@implementation RBStacksPushSegue

- (void)perform
{
	UIViewController *src = (UIViewController *) self.sourceViewController;
	UIViewController *dst = (UIViewController *) self.destinationViewController;

	RBStacksController * stack = (RBStacksController *)src.parentViewController;
	[stack pushViewController:dst animated:YES];
}

@end

@implementation RBStacksPopSegue

- (void)perform
{
	UIViewController *src = (UIViewController *) self.sourceViewController;

	RBStacksController * stack = (RBStacksController *)src.parentViewController;
	[stack popViewController];
}

@end

@implementation RBStacksRevealSegue

- (void)perform
{
	UIViewController *src = (UIViewController *) self.sourceViewController;

	RBStacksController * stack = (RBStacksController *)src.parentViewController;
	[stack reveal:src];
}

@end

@implementation RBStacksUnRevealSegue

- (void)perform
{
	UIViewController *src = (UIViewController *) self.sourceViewController;

	RBStacksController * stack = (RBStacksController *)src.parentViewController;
	[stack unReveal:src];
}

@end

@implementation RBStacksRemoveSegue

- (void)perform
{
	UIViewController *src = (UIViewController *) self.sourceViewController;

	RBStacksController * stack = (RBStacksController *)src.parentViewController;
	[stack popViewController:src];
}

@end