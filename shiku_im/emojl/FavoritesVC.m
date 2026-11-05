//
//  FavoritesVC.m
//  shiku_im
//
//  Created by p on 2017/9/14.
//  Copyright © 2017年 Reese. All rights reserved.
//

#import "FavoritesVC.h"
#import "RITLPhotosViewController.h"
#import "JXChatViewController.h"
@interface FavoritesVC ()<UIScrollViewDelegate,UIPopoverControllerDelegate,UINavigationControllerDelegate,UIActionSheetDelegate,UIImagePickerControllerDelegate,UIActionSheetDelegate>

@property (nonatomic, assign) int margin;
@property (nonatomic, assign) int tempN;
@property (nonatomic, assign) int maxPage;
@property (nonatomic, strong) UIScrollView *sv;
@property (nonatomic, strong) UIPageControl *pc;

@property (nonatomic, strong) NSMutableArray *delBtns;

@end

@implementation FavoritesVC


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.modalPresentationStyle = UIModalPresentationNone;
    
    _delBtns = [NSMutableArray array];
    
    _margin = 18;
    //    tempN = (JX_SCREEN_WIDTH <= 320) ? 8:10;
    _tempN = JX_SCREEN_WIDTH / (60 + _margin);
    
    if (((_tempN + 1) * 60 + _tempN * _margin) <= JX_SCREEN_WIDTH) {
        _tempN += 1;
    }
    
    _margin = (JX_SCREEN_WIDTH - _tempN * 60) / (_tempN + 1);
    
//    if (g_myself.favorites.count <= 0) {
//        [g_server userCollectionListWithType:6 pageIndex:0 toView:self];
        [g_server userEmojiListWithPageIndex:0 toView:self];
//    }
    
    [g_notify addObserver:self selector:@selector(refresh) name:kFavoritesRefresh object:nil];
}

-(void)create {
    
    NSMutableArray * mutableArray = g_myself.favorites;
    if(mutableArray.count <= 0)
    {
        [g_myself.favorites addObject:@""];
    }
    else
    {
        id firstObject = g_myself.favorites.firstObject;
        if(![firstObject isKindOfClass:[NSString class]])
        {
            [g_myself.favorites addObject:@""];
        }
    }
    int m = fmod([g_myself.favorites count], (_tempN * 2));
    _maxPage = (int)[g_myself.favorites count]/(_tempN*2);
    if(m != 0)
        _maxPage++;
    
    [self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_delBtns removeAllObjects];
    
    _sv = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height-20)];
    _sv.contentSize = CGSizeMake(WIDTH_PAGE*_maxPage, self.view.frame.size.height-20);
    _sv.pagingEnabled = YES;
    _sv.scrollEnabled = YES;
    _sv.delegate = self;
    _sv.showsVerticalScrollIndicator = NO;
    _sv.showsHorizontalScrollIndicator = NO;
    _sv.userInteractionEnabled = YES;

    _sv.minimumZoomScale = 1;
    _sv.maximumZoomScale = 1;
    _sv.decelerationRate = 0.01f;
    _sv.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_sv];
    //    [_sv release];
    
    int n = 0;
    int startX = (JX_SCREEN_WIDTH - _tempN * 60 - (_tempN - 1) * _margin) / 2;

    for(int i=0;i<_maxPage;i++){
        int x=WIDTH_PAGE*i + startX,y=0;
        for(int j=0;j<_tempN * 2;j++){
            if(n>=[g_myself.favorites count])
                break;
            if(i == 0 && j == 0)
            {
                UIImageView * image = [[UIImageView alloc]initWithFrame:CGRectMake(x, y+10, 60, 60)];
                NSLog(@"image ======= %f,%f",image.frame.origin.x,image.frame.origin.y);
                NSLog(@"svframe ======= %f,%f,%f,%f",self.view.frame.origin.x,self.view.frame.origin.y,self.view.frame.size.width,self.view.frame.size.height);
                image.image = [UIImage imageNamed:@"im_addImage"];
                [_sv addSubview:image];

                UITapGestureRecognizer * tapGes = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tap:)];
                tapGes.numberOfTapsRequired = 1;
                tapGes.numberOfTouchesRequired = 1;
                image.userInteractionEnabled = YES;
                [image addGestureRecognizer:tapGes];
            }
            else
            {
                JXImageView *iv = [[JXImageView alloc] initWithFrame:CGRectMake(x, y+10, 60, 60)];
                iv.tag = n;
                NSDictionary *dict = g_myself.favorites[n];
                NSString *url = dict[@"url"];
                [iv sd_setImageWithURL:[NSURL URLWithString:url] placeholderImage:[UIImage imageNamed:@"Default_Gray"]];
                iv.delegate = self;
                iv.didTouch = @selector(actionSelect:);
                [_sv addSubview:iv];

                // 长按删除手势
                UILongPressGestureRecognizer *lg = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longGestureAction:)];
                [iv addGestureRecognizer:lg];

                // 删除按钮
                JXImageView* del = [[JXImageView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(iv.frame) - 15, iv.frame.origin.y - 5, 20, 20)];
                del.didTouch = @selector(onDelete:);
                del.delegate = self;
                del.tag = n;
                del.image = [UIImage imageNamed:@"delete"];
                del.hidden = YES;
                [_sv addSubview:del];
                [_delBtns addObject:del];
            }
            if ((j + 1) % _tempN == 0) {
                x = WIDTH_PAGE*i + startX;
                y += 70;
            }else {
                x += 60 + _margin;
            }
            n++;
        }
    }

    _pc = [[UIPageControl alloc]initWithFrame:CGRectMake(100, self.view.frame.size.height-30, JX_SCREEN_WIDTH-200, 30)];
    _pc.numberOfPages  = _maxPage;
    _pc.pageIndicatorTintColor = [UIColor grayColor];
    _pc.currentPageIndicatorTintColor = [UIColor blackColor];
    _pc.userInteractionEnabled = NO;
    [_pc addTarget:self action:@selector(actionPage) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_pc];
    
}

- (void)refresh {
    
    [self create];
}

//点击选择从图库或者拍照
-(void)tap:(UITapGestureRecognizer *)ges
{
    UIActionSheet * actionSheet = [[UIActionSheet alloc]initWithTitle:@"标题" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"照相",@"相册", nil];
    [actionSheet setActionSheetStyle:UIActionSheetStyleBlackOpaque];
    [actionSheet showInView:self.view.window];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        
        [self addOfCamera];
    }
    else if(buttonIndex == 1)
    {
        
        [self addOfAlbum];
    }
}

- (void) addOfAlbum
{
    UIImagePickerController *pickerImage = [[UIImagePickerController alloc] init];
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        pickerImage.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        pickerImage.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:pickerImage.sourceType];
    }
    pickerImage.delegate = self;
    pickerImage.allowsEditing = YES;
    int tag = (int)g_navigation.subViews.count - 1;
    JXChatViewController * chatView = (JXChatViewController *)[g_navigation.subViews objectAtIndex:tag];
    [chatView presentViewController:pickerImage animated:YES completion:nil];
}

- (void) addOfCamera
{
    UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera;
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = sourceType;
    picker.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark –
#pragma mark Camera View Delegate Methods
- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIImage *image;
    picker.allowsEditing = YES;
    if (picker.sourceType == UIImagePickerControllerSourceTypePhotoLibrary){
        [self dismissViewControllerAnimated:YES completion:nil];
        image = [info objectForKey:UIImagePickerControllerEditedImage];
    }
    else{
        [self dismissViewControllerAnimated:YES completion:nil];
        image = [info objectForKey:UIImagePickerControllerEditedImage];
    }
    
    [self performSelector:@selector(saveImage:)
               withObject:image
               afterDelay:0.5];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self refresh];
    int tag = (int)g_navigation.subViews.count - 1;
    JXChatViewController * chatView = (JXChatViewController *)[g_navigation.subViews objectAtIndex:tag];
    [chatView dismissViewControllerAnimated:YES completion:nil];
}

-(void)saveImage:(UIImage *)image
{
    //先把image上传到服务器得到地址，然后再请求收藏接口。
    
//    NSString *type = [NSString stringWithFormat:@"%ld",collectType];
//    NSMutableDictionary *dataDict = [[NSMutableDictionary alloc] init];
//    if (collectType != CollectTypeEmoji) {
//        [dataDict setValue:msg.messageId forKey:@"msgId"];
//    }
//    [dataDict setValue:msg.content forKey:@"msg"];
//    [dataDict setValue:type forKey:@"type"];
//    [dataDict setValue:self.roomJid forKey:@"roomJid"];
//    [dataDict setValue:@0 forKey:@"collectType"];
//    [dataDict setValue:msg.content forKey:@"url"];
//
//    [emoji addObject:dataDict];
//    //    NSString * jsonString = [[SBJsonWriter new] stringWithObject:[msg toDictionary]];
//    //    [g_server addFavoriteWithContent:jsonString type:collectType toView:self];
//    [g_server addFavoriteWithEmoji:emoji toView:self];
    
//    http://115.28.211.108:8092/user/emoji/add?&secret=2e2975974ecbe050e513d9949142bc7b&emoji=[{"msg":"http://115.28.211.108/group1/M00/00/00/rB_mj13R_jqAfaX2AAA_xKGKMvs234.jpg","type":"6","collectType":0,"url":"http://115.28.211.108/group1/M00/00/00/rB_mj13R_jqAfaX2AAA_xKGKMvs234.jpg"}]&time=1574070860&access_token=8fc08e1e9ff045e19b654872cf4586ac
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if ([UIDevice currentDevice].systemVersion.floatValue < 11) {
        return;
    }
    if ([viewController isKindOfClass:NSClassFromString(@"PUPhotoPickerHostViewController")]) {
        [viewController.view.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.frame.size.width < 42) {
                [viewController.view sendSubviewToBack:obj];
                *stop = YES;
            }
        }];
    }
}

// 点击发送
-(void)actionSelect:(UIView*)sender
{
    NSDictionary *dict = [g_myself.favorites objectAtIndex:sender.tag];
    NSString* s = dict[@"url"];
    if ([self.delegate respondsToSelector:@selector(selectFavoritWithString:)]) {
        [self.delegate selectFavoritWithString:s];
    }
}

// 长按显示删除按钮
- (void)longGestureAction:(UILongPressGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        NSInteger n = gestureRecognizer.view.tag;
        for (NSInteger i = 0; i < _delBtns.count; i ++) {
            JXImageView *iv = _delBtns[i];
            if (i == n) {
                iv.hidden = !iv.hidden;
            }else {
                iv.hidden = YES;
            }
            
        }
        
    }
}

// 删除
- (void)onDelete:(UIView *)view {
    NSInteger n = view.tag;
    if ([self.delegate respondsToSelector:@selector(deleteFavoritWithString:)]) {
        NSDictionary *dict = [g_myself.favorites objectAtIndex:n];
        NSString* s = dict[@"emojiId"];
        [self.delegate deleteFavoritWithString:s];
        [g_myself.favorites removeObjectAtIndex:n];
        [self create];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    for (NSInteger i = 0; i < _delBtns.count; i ++) {
        JXImageView *iv = _delBtns[i];
        iv.hidden = YES;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    int index = scrollView.contentOffset.x/JX_SCREEN_WIDTH;
    int mod   = fmod(scrollView.contentOffset.x,JX_SCREEN_WIDTH);
    if( mod >= JX_SCREEN_WIDTH/2)
        index++;
    _pc.currentPage = index;
}

- (void) setPage
{
    _sv.contentOffset = CGPointMake(WIDTH_PAGE*_pc.currentPage, 0.0f);
    [_pc setNeedsDisplay];
}

-(void)actionPage{
    [self setPage];
}

-(void) didServerResultSucces:(JXConnection*)aDownload dict:(NSDictionary*)dict array:(NSArray*)array1{
    
    if ([aDownload.action isEqualToString:act_userEmojiList]) {
        
        [g_myself.favorites removeAllObjects];
        [g_myself.favorites addObjectsFromArray:array1];
        
        [self create];
        
    }
}

-(int) didServerResultFailed:(JXConnection*)aDownload dict:(NSDictionary*)dict{

    return hide_error;
}

-(int) didServerConnectError:(JXConnection*)aDownload error:(NSError *)error{//error为空时，代表超时
    
    return hide_error;
}

-(void) didServerConnectStart:(JXConnection*)aDownload{
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
