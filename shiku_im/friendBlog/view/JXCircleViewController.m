//
//  JXCircleViewController.m
//  shiku_im
//
//  Created by qiudezheng on 2020/1/9.
//  Copyright © 2020 Reese. All rights reserved.
//

#import "JXCircleViewController.h"

@interface JXCircleViewController()<UIWebViewDelegate>
@property(strong,nonatomic)UIWebView * webView;
@property(strong,nonatomic)UIButton * backButton;
@end

@implementation JXCircleViewController
{
    ATMHud* _wait;
    //    admobViewController* _pSelf;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"财富";
    
    UIView * navigationView = [[UIView alloc]initWithFrame:CGRectMake(0, -20, JX_SCREEN_WIDTH, 85)];
    if(JX_SCREEN_HEIGHT >= 812)
    {
        navigationView.frame = CGRectMake(0, -20, JX_SCREEN_WIDTH, 105);
    }
    navigationView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:navigationView];
    
    UILabel * label = [[UILabel alloc]initWithFrame:CGRectMake(0, 25, JX_SCREEN_WIDTH, 85)];
    if(JX_SCREEN_HEIGHT >= 812)
    {
        label.frame = CGRectMake(0, 40, JX_SCREEN_WIDTH, 80);
    }
    label.text = @"财富";
    label.textColor = [UIColor blackColor];
    label.font = [UIFont systemFontOfSize:18.0f];
    label.textAlignment = NSTextAlignmentCenter;
    [navigationView addSubview:label];
    
    self.backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.backButton.frame = CGRectMake(15, 45, 40, 40);
    if(JX_SCREEN_HEIGHT >= 812)
    {
        self.backButton.frame = CGRectMake(15, 65, 40, 40);
    }
    [self.backButton setImage:[UIImage imageNamed:@"title_back_black"] forState:UIControlStateNormal];
    self.backButton.hidden = YES;
    [self.backButton addTarget:self action:@selector(backButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [navigationView addSubview:self.backButton];
    
    self.webView = [[UIWebView alloc]initWithFrame:CGRectMake(0, navigationView.frame.origin.y + navigationView.frame.size.height, JX_SCREEN_WIDTH, JX_SCREEN_HEIGHT - self.tabBarController.tabBar.frame.size.height - (navigationView.frame.origin.y + navigationView.frame.size.height) - 44)];
    self.webView.backgroundColor = [UIColor whiteColor];
    if(JX_SCREEN_HEIGHT >= 812)
    {
        self.webView.frame = CGRectMake(0, navigationView.frame.origin.y + navigationView.frame.size.height, JX_SCREEN_WIDTH, JX_SCREEN_HEIGHT - self.tabBarController.tabBar.frame.size.height - (navigationView.frame.origin.y + navigationView.frame.size.height) - 80);
    }
    self.webView.delegate = self;
    NSString * stringUrl = [NSString stringWithFormat:@"%@",@"http://45.91.226.133:22330/ManagePictures/index"];
    NSURL * url = [NSURL URLWithString:stringUrl];
    NSURLRequest * request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
    [self.view addSubview:self.webView];
    
    
}

-(void)backButtonClicked:(UIButton *)sender
{
    [self.webView goBack];
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if(![request.URL.absoluteString isEqualToString:@"http://45.91.226.133:22330/ManagePictures/index"])
    {
        self.backButton.hidden = NO;
    }
    else
    {
        self.backButton.hidden = YES;
    }
    return YES;
}

-(void)webViewDidStartLoad:(UIWebView *)webView
{
    [_wait start:@"正在加载"];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView
{
    [_wait stop];
}
@end
