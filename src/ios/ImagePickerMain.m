

#import "ImagePickerMain.h"
#import "UIImage+Luban_iOS_Extension_h.h"

#define CDV_PHOTO_PREFIX @"cdv_photo_"

@interface ImagePicker ()<TZImagePickerControllerDelegate,UIImagePickerControllerDelegate,UIAlertViewDelegate,UINavigationControllerDelegate> {
    NSMutableArray *_selectedPhotos;
    NSMutableArray *_selectedAssets;
    BOOL _isSelectOriginalPhoto;

    CGFloat _itemWH;
    CGFloat _margin;
}

@end

@implementation ImagePicker

/**
 *  插件初始化
 */
- (void)pluginInitialize
{
    _enableShowTakePhoto = true;
    _enableShowTakeVideo = true;
    _enableSortAscending = true;
    _enablePickingVideo = false;
    _enablePickingImage = true;
    _enablePickingGif = true;
    _enablePickingOriginalPhoto = true;
    _enableShowSheet = false;
    _enableCrop = false;
    _enableCircleCrop = false;
    _enablePickingMuitlpleVideo = true;
    _enableSelectedIndex = true;
    
    _maxCountTF = 9;
    _columnNumberTF = 4;
    _width = 720;
    _height = 960;
    _quality = 80;

}


/**
 * 调用相册/相机获取图片
 */
- (void)getPictures:(CDVInvokedUrlCommand *)command{
    _callback = command.callbackId;

    NSDictionary *paramOptions = [command.arguments objectAtIndex: 0];

    self.maxCountTF  = [[paramOptions objectForKey:@"maximumImagesCount"] integerValue];
    self.width  = [[paramOptions objectForKey:@"width"] integerValue];
    self.height  = [[paramOptions objectForKey:@"height"] integerValue];
    self.quality  = [[paramOptions objectForKey:@"quality"] integerValue];
    self.enablePickingOriginalPhoto = [[paramOptions objectForKey:@"enablePickOriginal"] boolValue];

    if (self.maxCountTF <= 0) {
        return;
    }
    TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:self.maxCountTF columnNumber:self.columnNumberTF delegate:(id<TZImagePickerControllerDelegate>)self pushPhotoPickerVc:YES];


#pragma mark - 四类个性化设置，这些参数都可以不传，此时会走默认设置
    imagePickerVc.isSelectOriginalPhoto = YES;

    if (self.maxCountTF > 1) {
        // 1.设置目前已经选中的图片数组
        imagePickerVc.selectedAssets = _selectedAssets; // 目前已经选中的图片数组
    }
    imagePickerVc.allowTakePicture = YES; // 在内部显示拍照按钮

    // 2. Set the appearance
    // 2. 在这里设置imagePickerVc的外观
    // imagePickerVc.navigationBar.barTintColor = [UIColor greenColor];
    // imagePickerVc.oKButtonTitleColorDisabled = [UIColor lightGrayColor];
    // imagePickerVc.oKButtonTitleColorNormal = [UIColor greenColor];
    // imagePickerVc.navigationBar.translucent = NO;

    // 3. Set allow picking video & photo & originalPhoto or not
    // 3. 设置是否可以选择视频/图片/原图
    imagePickerVc.allowPickingVideo = self.enablePickingVideo;
    imagePickerVc.allowPickingImage = self.enablePickingImage;
    imagePickerVc.allowPickingOriginalPhoto = NO;
    imagePickerVc.allowPickingGif = self.enablePickingGif;
    imagePickerVc.allowPickingMultipleVideo = self.enablePickingMuitlpleVideo; // 是否可以多选视频

    // 4. 照片排列按修改时间升序
    imagePickerVc.sortAscendingByModificationDate = self.enableSortAscending;

    // imagePickerVc.minImagesCount = 3;
    // imagePickerVc.alwaysEnableDoneBtn = YES;

    // imagePickerVc.minPhotoWidthSelectable = 3000;
    // imagePickerVc.minPhotoHeightSelectable = 2000;

    /// 5. Single selection mode, valid when maxImagesCount = 1
    /// 5. 单选模式,maxImagesCount为1时才生效
    imagePickerVc.showSelectBtn = NO;
    imagePickerVc.allowCrop = self.enableCrop;
    imagePickerVc.needCircleCrop = self.enableCircleCrop;
    // 设置竖屏下的裁剪尺寸
    //NSInteger left = 30;
    //NSInteger widthHeight = self.view.tz_width - 2 * left;
    //NSInteger top = (self.view.tz_height - widthHeight) / 2;
    //imagePickerVc.cropRect = CGRectMake(left, top, widthHeight, widthHeight);
    // 设置横屏下的裁剪尺寸
    // imagePickerVc.cropRectLandscape = CGRectMake((self.view.tz_height - widthHeight) / 2, left, widthHeight, widthHeight);
    /*
     [imagePickerVc setCropViewSettingBlock:^(UIView *cropView) {
     cropView.layer.borderColor = [UIColor redColor].CGColor;
     cropView.layer.borderWidth = 2.0;
     }];*/
    
    //imagePickerVc.allowPreview = NO;
    // 自定义导航栏上的返回按钮
    /*
     */
     [imagePickerVc setNavLeftBarButtonSettingBlock:^(UIButton *leftButton){
        [leftButton setTitle:[NSBundle tz_localizedStringForKey:@"Back"] forState:UIControlStateNormal];
        leftButton.titleLabel.font = [UIFont systemFontOfSize:15];
     }];
     imagePickerVc.delegate = self;
    
    // Deprecated, Use statusBarStyle
    // imagePickerVc.isStatusBarDefault = NO;
    imagePickerVc.statusBarStyle = UIStatusBarStyleLightContent;
    
    // 设置是否显示图片序号
    imagePickerVc.showSelectedIndex = self.enableSelectedIndex;
    
    // 设置首选语言 / Set preferred language
    // imagePickerVc.preferredLanguage = @"zh-Hans";
    
    // 设置languageBundle以使用其它语言 / Set languageBundle to use other language
    // imagePickerVc.languageBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"tz-ru" ofType:@"lproj"]];
#pragma mark - 到这里为止

    // You can get the photos by block, the same as by delegate.
    // 你可以通过block或者代理，来得到用户选择的照片.
    [imagePickerVc setDidFinishPickingPhotosHandle:^(NSArray<UIImage *> *photos, NSArray *assets, BOOL isSelectOriginalPhoto) {

            if(isSelectOriginalPhoto) {
                __block NSMutableArray *pathsArr = [[NSMutableArray alloc] init];
                
                [self saveOriginalImage:assets currentIdx:0 originalPathArray:pathsArr completion:^(NSMutableArray *paths) {
                    
                    NSLog(@"All finished.");
                    
                    NSDictionary* result = @{@"images": paths, @"isOrigin": @(YES)};
                    
                    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result];
                    
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                    
                    _isSelectOriginalPhoto = FALSE;
                }];
            }
            else {
                
                /*NSMutableArray *pathsArr = [[NSMutableArray alloc] init];
                
                for(int i=0; i<[photos count]; i++) {
                    UIImage *photo = photos[i];
                    id asset = assets[i];
                    
                    NSString *fileName = [self getFileNameForAsset:asset];
                    
                    NSString *filePath = [self saveImgToFile:photo withName:fileName];
                    
                    [pathsArr addObject: filePath];
                }
                
                if([pathsArr count] != 0 && [pathsArr count] == [photos count]) {
                    NSDictionary* result = @{@"images": pathsArr, @"isOrigin": @(NO)};
                    
                    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result];
                    
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                }
                
                _isSelectOriginalPhoto = FALSE;*/
                
                
                __block NSMutableArray *pathsArr = [[NSMutableArray alloc] init];
                
                [self saveCompressImage:assets currentIdx:0 compressedPathArray:pathsArr completion:^(NSMutableArray *paths) {
                    
                    NSLog(@"All finished.");
                    
                    NSDictionary* result = @{@"images": paths, @"isOrigin": @(NO)};
                    
                    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result];
                    
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                    
                    _isSelectOriginalPhoto = FALSE;
                }];
            }
            
            _selectedAssets = nil;

    }];

    [self.viewController presentViewController:imagePickerVc animated:YES completion:nil];
}

//获取原始文件名
- (NSString *)getFileNameForAsset:(id)asset {
    NSString *fileName;
    
    if ([asset isKindOfClass:[PHAsset class]]) {
        PHAsset *phAsset = (PHAsset *)asset;
        fileName = [phAsset valueForKey:@"filename"];
    } else if ([asset isKindOfClass:[ALAsset class]]) {
        ALAsset *alAsset = (ALAsset *)asset;
        fileName = alAsset.defaultRepresentation.filename;
    }
    
    return fileName;
}

- (void)saveOriginalImage:(NSArray *)assets currentIdx:(NSInteger)idx  originalPathArray:(NSMutableArray *)originalPaths completion:(void (^)(NSMutableArray *photos))completion {
    if([assets count] - 1 >= idx) {
        id asset = assets[idx];
        
        __block NSInteger index = idx;
        
        NSString *originName = [self getFileNameForAsset:asset];
        NSString *originExt = [[originName pathExtension] lowercaseString];

        [[TZImageManager manager] getOriginalPhotoWithAsset:asset newCompletion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
            if (!isDegraded) {
                @autoreleasepool {
                    NSString *fileName = [[[originName lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:@"JPG"];
                    NSData *imageData = UIImageJPEGRepresentation(photo, 0.9);
                    NSString *path = [self saveNSDataToFile:imageData withName:fileName];
                    NSDictionary* fileObj = @{
                                            @"path": path,
                                            @"width": @([asset pixelWidth]),
                                            @"height": @([asset pixelHeight]),
                                            @"size": @([imageData length])
                                            };
                    [originalPaths addObject:fileObj];
                    index += 1;
                    [self saveOriginalImage:assets currentIdx:index originalPathArray:originalPaths completion:completion];
                };
            };
        }];
    }
    else {
        if (completion) {
            completion(originalPaths);
        }
    }
}
    
- (void)saveCompressImage:(NSArray *)assets currentIdx:(NSInteger)idx compressedPathArray:(NSMutableArray *)compressedPaths completion:(void (^)(NSMutableArray *photos))completion {
    if([assets count] - 1 >= idx) {
        id asset = assets[idx];
        
        __block NSInteger index = idx;
        
        NSString *originName = [self getFileNameForAsset:asset];
        NSString *originExt = [[originName pathExtension] lowercaseString]; // origin file extension
        
        __block int maxWidth = (int)self.width;
        __block int maxHeight = (int)self.height;
        __block int quality = (int)self.quality;
        
        // do not compress gif
        if([originExt isEqualToString:@"gif"]) {
            [[TZImageManager manager] getOriginalPhotoDataWithAsset:asset completion:^(NSData *data, NSDictionary *info, BOOL isDegraded) {
                
                NSString *path = [self saveNSDataToFile:data withName:originName];
                NSDictionary* fileObj = @{
                                          @"path": path,
                                          @"width": @([asset pixelWidth]),
                                          @"height": @([asset pixelHeight]),
                                          @"size": @([data length])
                                          };
                [compressedPaths addObject:fileObj];
                
                index += 1;
                [self saveCompressImage:assets currentIdx:index compressedPathArray:compressedPaths completion:completion];
            }];
        }
        else {
            [[TZImageManager manager] getOriginalPhotoWithAsset:asset newCompletion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
                
                if(!isDegraded) {
                    NSData *compressed;

                    if(maxWidth > 0 && maxHeight > 0 && quality > 0) {
                        float q = (float)quality/100;
                        compressed = [UIImage compressScale:photo maxWidth:maxWidth maxHeight:maxHeight quality:q];
                    }
                    else { // maxWidth 和 maxHeight 如果小于0，就自动压缩分辨率
                        compressed = [UIImage lubanCompressImage:photo];
                    }

                    UIImage *newImage   = [UIImage imageWithData:compressed];

                    NSString *fileName = [[[originName lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:@"JPG"];
                    NSString *path = [self saveNSDataToFile:compressed withName:fileName];
                    NSDictionary* fileObj = @{
                                              @"path": path,
                                              @"width": @(newImage.size.width * newImage.scale),
                                              @"height": @(newImage.size.height * newImage.scale),
                                              @"size": @([compressed length])
                                              };
                    [compressedPaths addObject:fileObj];

                    index += 1;
                    [self saveCompressImage:assets currentIdx:index compressedPathArray:compressedPaths completion:completion];
                }
            }];
        }
    }
    else {
        if (completion) {
            completion(compressedPaths);
        }
    }
}

// 创建临时保存目录
- (NSString *)ensureSaveDirectory {
    //NSString *storeDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString *storeDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"ImagePicker"];
    
    BOOL isDir = TRUE;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:storeDir isDirectory:&isDir];
    
    if(!exists) {
        [[NSFileManager defaultManager] createDirectoryAtPath:storeDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return storeDir;
}
    
//保存JPG图片
/*- (NSString *)saveImgToFile:(UIImage *)currentImage withName:(NSString*)imageName{

    NSData *imageData = UIImageJPEGRepresentation(currentImage, 1);

    NSString *fileName = [[[imageName lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:@"JPG"];

    // 获取沙盒临时路径
    NSString *fullPath = [[self ensureSaveDirectory] stringByAppendingPathComponent:fileName];

    // 将图片写入文件
    [imageData writeToFile:fullPath atomically:NO];

    return fullPath;

}*/
    
//保存原始图片
- (NSString *)saveNSDataToFile:(NSData *)imageData withName:(NSString*)imageName{
    // 获取沙盒临时路径
    NSString *fullPath = [[self ensureSaveDirectory] stringByAppendingPathComponent:imageName];
    
    // 将图片写入文件
    [imageData writeToFile:fullPath atomically:NO];
    
    return fullPath;
    
}


/*- (UIImage*)imageByScalingNotCroppingForSize:(UIImage*)anImage toSize:(CGSize)frameSize
{
    UIImage* sourceImage = anImage;
    UIImage* newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = frameSize.width;
    CGFloat targetHeight = frameSize.height;
    CGFloat scaleFactor = 0.0;
    CGSize scaledSize = frameSize;

    if (CGSizeEqualToSize(imageSize, frameSize) == NO) {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;

        // opposite comparison to imageByScalingAndCroppingForSize in order to contain the image within the given bounds
        if (widthFactor == 0.0) {
            scaleFactor = heightFactor;
        } else if (heightFactor == 0.0) {
            scaleFactor = widthFactor;
        } else if (widthFactor > heightFactor) {
            scaleFactor = heightFactor; // scale to fit height
        } else {
            scaleFactor = widthFactor; // scale to fit width
        }
        scaledSize = CGSizeMake(width * scaleFactor, height * scaleFactor);
    }

    UIGraphicsBeginImageContext(scaledSize); // this will resize

    [sourceImage drawInRect:CGRectMake(0, 0, scaledSize.width, scaledSize.height)];

    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if (newImage == nil) {
        NSLog(@"could not scale image");
    }

    // pop the context to get back to the default
    UIGraphicsEndImageContext();
    return newImage;
}*/


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (UIImagePickerController *)imagePickerVc {
    if (_imagePickerVc == nil) {
        _imagePickerVc = [[UIImagePickerController alloc] init];
        _imagePickerVc.delegate = self;
        // set appearance / 改变相册选择页的导航栏外观
        _imagePickerVc.navigationBar.barTintColor = self.viewController.navigationController.navigationBar.barTintColor;
        _imagePickerVc.navigationBar.tintColor = self.viewController.navigationController.navigationBar.tintColor;
        UIBarButtonItem *tzBarItem, *BarItem;
        if (iOS9Later) {
            tzBarItem = [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[TZImagePickerController class]]];
            BarItem = [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UIImagePickerController class]]];
        } else {
            tzBarItem = [UIBarButtonItem appearanceWhenContainedIn:[TZImagePickerController class], nil];
            BarItem = [UIBarButtonItem appearanceWhenContainedIn:[UIImagePickerController class], nil];
        }
        NSDictionary *titleTextAttributes = [tzBarItem titleTextAttributesForState:UIControlStateNormal];
        [BarItem setTitleTextAttributes:titleTextAttributes forState:UIControlStateNormal];
    }
    return _imagePickerVc;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

#pragma mark - TZImagePickerController

- (void)pushTZImagePickerController {
    if (self.maxCountTF <= 0) {
        return;
    }
    TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:self.maxCountTF columnNumber:self.columnNumberTF delegate:self pushPhotoPickerVc:YES];


#pragma mark - 五类个性化设置，这些参数都可以不传，此时会走默认设置
    imagePickerVc.isSelectOriginalPhoto = _isSelectOriginalPhoto;

    if (self.maxCountTF > 1) {
        // 1.设置目前已经选中的图片数组
        imagePickerVc.selectedAssets = _selectedAssets; // 目前已经选中的图片数组
    }
    imagePickerVc.allowTakePicture = self.enableShowTakePhoto; // 在内部显示拍照按钮
    imagePickerVc.allowTakeVideo = self.enableShowTakeVideo;   // 在内部显示拍视频按钮
    imagePickerVc.videoMaximumDuration = 10; // 视频最大拍摄时间
    [imagePickerVc setUiImagePickerControllerSettingBlock:^(UIImagePickerController *imagePickerController) {
        imagePickerController.videoQuality = UIImagePickerControllerQualityTypeHigh;
    }];
    
    // imagePickerVc.photoWidth = 1000;

    // 2. Set the appearance
    // 2. 在这里设置imagePickerVc的外观
    // if (iOS7Later) {
    //  imagePickerVc.navigationBar.barTintColor = [UIColor greenColor];
    // }
    // imagePickerVc.oKButtonTitleColorDisabled = [UIColor lightGrayColor];
    // imagePickerVc.oKButtonTitleColorNormal = [UIColor greenColor];
    // imagePickerVc.navigationBar.translucent = NO;
    imagePickerVc.iconThemeColor = [UIColor colorWithRed:31 / 255.0 green:185 / 255.0 blue:34 / 255.0 alpha:1.0];
    imagePickerVc.showPhotoCannotSelectLayer = YES;
    imagePickerVc.cannotSelectLayerColor = [[UIColor whiteColor] colorWithAlphaComponent:0.8];

    // 3. Set allow picking video & photo & originalPhoto or not
    // 3. 设置是否可以选择视频/图片/原图
    imagePickerVc.allowPickingVideo = self.enablePickingVideo;
    imagePickerVc.allowPickingImage = self.enablePickingImage;
    imagePickerVc.allowPickingOriginalPhoto = NO;
    imagePickerVc.allowPickingGif = self.enablePickingGif;
    imagePickerVc.allowPickingMultipleVideo = self.enablePickingMuitlpleVideo; // 是否可以多选视频

    // 4. 照片排列按修改时间升序
    imagePickerVc.sortAscendingByModificationDate = self.enableSortAscending;

    // imagePickerVc.minImagesCount = 3;
    // imagePickerVc.alwaysEnableDoneBtn = YES;

    // imagePickerVc.minPhotoWidthSelectable = 3000;
    // imagePickerVc.minPhotoHeightSelectable = 2000;

    /// 5. Single selection mode, valid when maxImagesCount = 1
    /// 5. 单选模式,maxImagesCount为1时才生效
    imagePickerVc.showSelectBtn = NO;
    imagePickerVc.allowCrop = self.enableCrop;
    imagePickerVc.needCircleCrop = self.enableCircleCrop;
    imagePickerVc.circleCropRadius = 100;
    imagePickerVc.isStatusBarDefault = NO;
    /*
     [imagePickerVc setCropViewSettingBlock:^(UIView *cropView) {
     cropView.layer.borderColor = [UIColor redColor].CGColor;
     cropView.layer.borderWidth = 2.0;
     }];*/

    //imagePickerVc.allowPreview = NO;
#pragma mark - 到这里为止

    // You can get the photos by block, the same as by delegate.
    // 你可以通过block或者代理，来得到用户选择的照片.
    [imagePickerVc setDidFinishPickingPhotosHandle:^(NSArray<UIImage *> *photos, NSArray *assets, BOOL isSelectOriginalPhoto) {


    }];

    [self.viewController presentViewController:imagePickerVc animated:YES completion:nil];
}

#pragma mark - UIImagePickerController

- (void)takePhoto:(CDVInvokedUrlCommand *)command {
    _callback = command.callbackId;
    
    NSDictionary *paramOptions = [command.arguments objectAtIndex: 0];
    
    self.maxCountTF  = [[paramOptions objectForKey:@"maximumImagesCount"] integerValue];
    self.width  = [[paramOptions objectForKey:@"width"] integerValue];
    self.height  = [[paramOptions objectForKey:@"height"] integerValue];
    self.quality  = [[paramOptions objectForKey:@"quality"] integerValue];
    
    [self checkTakePhoto];
}

- (void)checkTakePhoto {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if ((authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied) && iOS7Later) {
        // 无相机权限 做一个友好的提示
        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"无法使用相机" message:@"请在iPhone的""设置-隐私-相机""中允许访问相机" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"设置", nil];
        [alert show];
    } else if (authStatus == AVAuthorizationStatusNotDetermined) {
        // fix issue 466, 防止用户首次拍照拒绝授权时相机页黑屏
        if (iOS7Later) {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        [self checkTakePhoto];
                    });
                }
            }];
        } else {
            [self checkTakePhoto];
        }
        // 拍照之前还需要检查相册权限
    } else if ([TZImageManager authorizationStatus] == 2) { // 已被拒绝，没有相册权限，将无法保存拍的照片
        if (iOS8Later) {
            UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"无法访问相册" message:@"请在iPhone的""设置-隐私-相册""中允许访问相册" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"设置", nil];
            [alert show];
        } else {
            UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"无法访问相册" message:@"请在iPhone的""设置-隐私-相册""中允许访问相册" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [alert show];
        }
    } else if ([TZImageManager authorizationStatus] == 0) { // 未请求过相册权限
        [[TZImageManager manager] requestAuthorizationWithCompletion:^{
            [self checkTakePhoto];
        }];
    } else {
        [self pushImagePickerController];
    }
}

// 调用相机
- (void)pushImagePickerController {
    // 提前定位
    [[TZLocationManager manager] startLocationWithSuccessBlock:^(NSArray<CLLocation *> *locations) {
        _location = [locations firstObject];
    } failureBlock:^(NSError *error) {
        _location = nil;
    }];

    UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera;
    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
        self.imagePickerVc.sourceType = sourceType;
        if(iOS8Later) {
            _imagePickerVc.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        }
        [self.viewController presentViewController:_imagePickerVc animated:YES completion:nil];
    } else {
        NSLog(@"模拟器中无法打开照相机,请在真机中使用");
    }
}

- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    NSString *type = [info objectForKey:UIImagePickerControllerMediaType];
    if ([type isEqualToString:@"public.image"]) {
        TZImagePickerController *tzImagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:1 delegate:self];
        tzImagePickerVc.sortAscendingByModificationDate = self.enableSortAscending;
        [tzImagePickerVc showProgressHUD];
        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];

        // save photo and get asset / 保存图片，获取到asset
        [[TZImageManager manager] savePhotoWithImage:image location:self.location completion:^(PHAsset *asset, NSError *error){
            if (error) {
                [tzImagePickerVc hideProgressHUD];
                NSLog(@"图片保存失败 %@",error);
            } else {
                [[TZImageManager manager] getCameraRollAlbumWithFetchAssets:NO completion:^(TZAlbumModel *model) {
                    [[TZImageManager manager] getAssetsFromFetchResult:model.result completion:^(NSArray<TZAssetModel *> *models) {
                        [tzImagePickerVc hideProgressHUD];
                        TZAssetModel *assetModel = [models firstObject];
                        if (tzImagePickerVc.sortAscendingByModificationDate) {
                            assetModel = [models lastObject];
                        }
                        if (self.enableCrop) { // 允许裁剪,去裁剪
                            TZImagePickerController *imagePicker = [[TZImagePickerController alloc] initCropTypeWithAsset:assetModel.asset photo:image completion:^(UIImage *cropImage, id asset) {
                                [self refreshCollectionViewWithAddedAsset:asset image:cropImage];
                            }];
                            imagePicker.needCircleCrop = self.enableCircleCrop;
                            imagePicker.circleCropRadius = 100;
                            [self.viewController presentViewController:imagePicker animated:YES completion:nil];
                        } else {
                            [self refreshCollectionViewWithAddedAsset:assetModel.asset image:image];
                        }
                    }];
                }];
            }
        }];
    }
}

- (void)refreshCollectionViewWithAddedAsset:(id)asset image:(UIImage *)image {
    //_selectedPhotos = [NSMutableArray arrayWithArray:@[image]];
    _selectedAssets = [NSMutableArray arrayWithArray:@[asset]];
    //[_collectionView reloadData];

    if ([asset isKindOfClass:[PHAsset class]]) {
        PHAsset *phAsset = asset;
        NSLog(@"location:%@",phAsset.location);
    }
    
    if(_callback != NULL) {
        
        __block NSMutableArray *pathsArr = [[NSMutableArray alloc] init];
        
        [self saveCompressImage:_selectedAssets currentIdx:0 compressedPathArray:pathsArr completion:^(NSMutableArray *paths) {
            
            NSLog(@"All finished.");
            
            NSDictionary* result = @{@"images": paths, @"isOrigin": @(NO)};
            
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result];
            
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self->_callback];
        }];
    }
    _selectedAssets = nil;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    if ([picker isKindOfClass:[UIImagePickerController class]]) {
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
    
    if(_callback != NULL) {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"已取消"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:_callback];
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) { // 去设置界面，开启相机访问权限
        if (iOS8Later) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        }
    }
}

#pragma mark - TZImagePickerControllerDelegate

/// User click cancel button
/// 用户点击了取消
- (void)tz_imagePickerControllerDidCancel:(TZImagePickerController *)picker {
    NSLog(@"cancel");
    
    if(_callback != NULL) {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"已取消"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:_callback];
    }
}

// The picker should dismiss itself; when it dismissed these handle will be called.
// If isOriginalPhoto is YES, user picked the original photo.
// You can get original photo with asset, by the method [[TZImageManager manager] getOriginalPhotoWithAsset:completion:].
// The UIImage Object in photos default width is 828px, you can set it by photoWidth property.
// 这个照片选择器会自己dismiss，当选择器dismiss的时候，会执行下面的代理方法
// 如果isSelectOriginalPhoto为YES，表明用户选择了原图
// 你可以通过一个asset获得原图，通过这个方法：[[TZImageManager manager] getOriginalPhotoWithAsset:completion:]
// photos数组里的UIImage对象，默认是828像素宽，你可以通过设置photoWidth属性的值来改变它
- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingPhotos:(NSArray *)photos sourceAssets:(NSArray *)assets isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto {
    _selectedPhotos = [NSMutableArray arrayWithArray:photos];
    _selectedAssets = [NSMutableArray arrayWithArray:assets];
    _isSelectOriginalPhoto = isSelectOriginalPhoto;
    //[_collectionView reloadData];
    // _collectionView.contentSize = CGSizeMake(0, ((_selectedPhotos.count + 2) / 3 ) * (_margin + _itemWH));

    // 1.打印图片名字
    [self printAssetsName:assets];
    // 2.图片位置信息
    if (iOS8Later) {
        for (PHAsset *phAsset in assets) {
            NSLog(@"location:%@",phAsset.location);
        }
    }
}

// If user picking a video, this callback will be called.
// If system version > iOS8,asset is kind of PHAsset class, else is ALAsset class.
// 如果用户选择了一个视频，下面的handle会被执行
// 如果系统版本大于iOS8，asset是PHAsset类的对象，否则是ALAsset类的对象
- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingVideo:(UIImage *)coverImage sourceAssets:(id)asset {
    _selectedPhotos = [NSMutableArray arrayWithArray:@[coverImage]];
    _selectedAssets = [NSMutableArray arrayWithArray:@[asset]];
    // open this code to send video / 打开这段代码发送视频
    // [[TZImageManager manager] getVideoOutputPathWithAsset:asset completion:^(NSString *outputPath) {
    // NSLog(@"视频导出到本地完成,沙盒路径为:%@",outputPath);
    // Export completed, send video here, send by outputPath or NSData
    // 导出完成，在这里写上传代码，通过路径或者通过NSData上传

    // }];
    //[_collectionView reloadData];
    // _collectionView.contentSize = CGSizeMake(0, ((_selectedPhotos.count + 2) / 3 ) * (_margin + _itemWH));
}

// If user picking a gif image, this callback will be called.
// 如果用户选择了一个gif图片，下面的handle会被执行
- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingGifImage:(UIImage *)animatedImage sourceAssets:(id)asset {
    _selectedPhotos = [NSMutableArray arrayWithArray:@[animatedImage]];
    _selectedAssets = [NSMutableArray arrayWithArray:@[asset]];
    //[_collectionView reloadData];
}

// Decide album show or not't
// 决定相册显示与否
- (BOOL)isAlbumCanSelect:(NSString *)albumName result:(id)result {
    /*
     if ([albumName isEqualToString:@"个人收藏"]) {
     return NO;
     }
     if ([albumName isEqualToString:@"视频"]) {
     return NO;
     }*/
    return YES;
}

// Decide asset show or not't
// 决定asset显示与否
- (BOOL)isAssetCanSelect:(id)asset {
    /*
     if (iOS8Later) {
     PHAsset *phAsset = asset;
     switch (phAsset.mediaType) {
     case PHAssetMediaTypeVideo: {
     // 视频时长
     // NSTimeInterval duration = phAsset.duration;
     return NO;
     } break;
     case PHAssetMediaTypeImage: {
     // 图片尺寸
     if (phAsset.pixelWidth > 3000 || phAsset.pixelHeight > 3000) {
     // return NO;
     }
     return YES;
     } break;
     case PHAssetMediaTypeAudio:
     return NO;
     break;
     case PHAssetMediaTypeUnknown:
     return NO;
     break;
     default: break;
     }
     } else {
     ALAsset *alAsset = asset;
     NSString *alAssetType = [[alAsset valueForProperty:ALAssetPropertyType] stringValue];
     if ([alAssetType isEqualToString:ALAssetTypeVideo]) {
     // 视频时长
     // NSTimeInterval duration = [[alAsset valueForProperty:ALAssetPropertyDuration] doubleValue];
     return NO;
     } else if ([alAssetType isEqualToString:ALAssetTypePhoto]) {
     // 图片尺寸
     CGSize imageSize = alAsset.defaultRepresentation.dimensions;
     if (imageSize.width > 3000) {
     // return NO;
     }
     return YES;
     } else if ([alAssetType isEqualToString:ALAssetTypeUnknown]) {
     return NO;
     }
     }*/
    return YES;
}


#pragma mark - Private

/// 打印图片名字
- (void)printAssetsName:(NSArray *)assets {
    NSString *fileName;
    for (id asset in assets) {
        if ([asset isKindOfClass:[PHAsset class]]) {
            PHAsset *phAsset = (PHAsset *)asset;
            fileName = [phAsset valueForKey:@"filename"];
        } else if ([asset isKindOfClass:[ALAsset class]]) {
            ALAsset *alAsset = (ALAsset *)asset;
            fileName = alAsset.defaultRepresentation.filename;;
        }
        //NSLog(@"图片名字:%@",fileName);
    }
}

#pragma clang diagnostic pop

@end
