//
//  AssetHelper.m
//  DoImagePickerController
//
//  Created by Donobono on 2014. 1. 23..
//

#import "AssetHelper.h"

@implementation AssetHelper


+ (AssetHelper *)sharedAssetHelper
{
    static AssetHelper *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[AssetHelper alloc] init];
        [_sharedInstance initAsset];
    });
    
    return _sharedInstance;
}

- (void)initAsset
{
    
}

- (BOOL)isCameraRollAlbum:(PHAssetCollection *)metadata {
    NSString *versionStr = [[UIDevice currentDevice].systemVersion stringByReplacingOccurrencesOfString:@"." withString:@""];
    if (versionStr.length <= 1) {
        versionStr = [versionStr stringByAppendingString:@"00"];
    } else if (versionStr.length <= 2) {
        versionStr = [versionStr stringByAppendingString:@"0"];
    }
    CGFloat version = versionStr.floatValue;
    // 目前已知8.0.0 ~ 8.0.2系统，拍照后的图片会保存在最近添加中
    if (version >= 800 && version <= 802) {
        return ((PHAssetCollection *)metadata).assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumRecentlyAdded;
    } else {
        return ((PHAssetCollection *)metadata).assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary;
    }
}


- (void)getGroupList:(void (^)(NSArray *))result
{
    [self initAsset];
    
    _assetGroups = [[NSMutableArray alloc] init];
    PHFetchOptions *option = [[PHFetchOptions alloc] init];
    option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
   
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    
    for (PHAssetCollection *collection in smartAlbums) {
        // 有可能是PHCollectionList类的的对象，过滤掉
        if (![collection isKindOfClass:[PHAssetCollection class]]) continue;
        // 过滤空相册
        if (collection.estimatedAssetCount <= 0) continue;
        if (collection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumAllHidden) continue;
        if (collection.assetCollectionSubtype == 1000000201) continue; //『最近删除』相册
        PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:option];
        if (fetchResult.count < 1 && ![self isCameraRollAlbum:collection]) continue;
        
        [_assetGroups addObject:collection];
        
    }
    result(_assetGroups);

}

- (void)getPhotoListOfGroup:(PHCollection *)collection result:(void (^)(NSArray *))result
{
    [self initAsset];
    
    _assetPhotos = [[NSMutableArray alloc] init];
    PHFetchOptions *option = [[PHFetchOptions alloc] init];
    option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
    PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:(PHAssetCollection *)collection options:option];
    if (fetchResult.count > 0) {
        //        [_assetPhotos addObjectsFromArray:fetchResult];
        for (NSInteger i = 0; i < [fetchResult count]; i++) {
            [_assetPhotos addObject:fetchResult[i]];
        }
        result(_assetPhotos);
        
    }
}

- (void)getPhotoListOfGroupByIndex:(NSInteger)nGroupIndex result:(void (^)(NSArray *))result
{
    [self getPhotoListOfGroup:_assetGroups[nGroupIndex] result:^(NSArray *aResult) {

        result(_assetPhotos);
        
    }];
}

- (void)getSavedPhotoList:(void (^)(NSArray *))result error:(void (^)(NSError *))error
{
//    [self initAsset];
//
//    dispatch_async(dispatch_get_main_queue(), ^{
//
//        void (^assetGroupEnumerator)(ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop)
//        {
//            if ([[group valueForProperty:@"ALAssetsGroupPropertyType"] intValue] == ALAssetsGroupSavedPhotos)
//            {
//                [group setAssetsFilter:[ALAssetsFilter allPhotos]];
//
//                [group enumerateAssetsUsingBlock:^(ALAsset *alPhoto, NSUInteger index, BOOL *stop) {
//
//                    if(alPhoto == nil)
//                    {
//                        if (_bReverse)
//                            _assetPhotos = [[NSMutableArray alloc] initWithArray:[[_assetPhotos reverseObjectEnumerator] allObjects]];
//
//                        result(_assetPhotos);
//                        return;
//                    }
//
//                    [_assetPhotos addObject:alPhoto];
//                }];
//            }
//        };
//
//        void (^assetGroupEnumberatorFailure)(NSError *) = ^(NSError *err)
//        {
//            NSLog(@"Error : %@", [err description]);
//            error(err);
//        };
//
//        _assetPhotos = [[NSMutableArray alloc] init];
//        [_assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
//                                      usingBlock:assetGroupEnumerator
//                                    failureBlock:assetGroupEnumberatorFailure];
//    });
}

- (NSInteger)getGroupCount
{
    return _assetGroups.count;
}

- (NSInteger)getPhotoCountOfCurrentGroup
{
    return _assetPhotos.count;
}

- (NSDictionary *)getGroupInfo:(NSInteger)nIndex
{
    
    PHAssetCollection *collection = [_assetGroups objectAtIndex:nIndex];
    PHFetchOptions *option = [[PHFetchOptions alloc] init];
    option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
    PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:(PHAssetCollection *)collection options:option];
    
    PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
    PHAsset *asset = [assetsFetchResult firstObject];
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];

    options.synchronous = YES;
    options.resizeMode = PHImageRequestOptionsResizeModeExact;
    CGFloat scale = [UIScreen mainScreen].scale;
    CGFloat dimension = 128.0f;
    CGSize size = CGSizeMake(dimension*scale, dimension*scale);
    __block UIImage *posterImage = [UIImage imageNamed:@"loading_square_120px"];
    [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage *result, NSDictionary *info) {
        if ([[info valueForKey:@"PHImageResultIsDegradedKey"]integerValue]==0){
            if (result) {
                posterImage = result;
            }
        } else {
            // Do something with the regraded image
        }
        
    }];
    return @{@"name" : collection.localizedTitle,
             @"count" : @([fetchResult count]),
             @"thumbnail" : posterImage};
   
}

- (void)clearData
{
	_assetGroups = nil;
	_assetPhotos = nil;
}

#pragma mark - utils
- (UIImage *)getCroppedImage:(NSURL *)urlImage
{
    __block UIImage *iImage = nil;
//    __block BOOL bBusy = YES;
//
//    ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myasset)
//    {
//        ALAssetRepresentation *rep = [myasset defaultRepresentation];
//        NSString *strXMP = rep.metadata[@"AdjustmentXMP"];
//        if (strXMP == nil || [strXMP isKindOfClass:[NSNull class]])
//        {
//            CGImageRef iref = [rep fullResolutionImage];
//            if (iref)
//                iImage = [UIImage imageWithCGImage:iref scale:1.0 orientation:(UIImageOrientation)rep.orientation];
//            else
//                iImage = nil;
//        }
//        else
//        {
//            // to get edited photo by photo app
//            NSData *dXMP = [strXMP dataUsingEncoding:NSUTF8StringEncoding];
//
//            CIImage *image = [CIImage imageWithCGImage:rep.fullResolutionImage];
//
//            NSError *error = nil;
//            NSArray *filterArray = [CIFilter filterArrayFromSerializedXMP:dXMP
//                                                         inputImageExtent:image.extent
//                                                                    error:&error];
//            if (error) {
//                NSLog(@"Error during CIFilter creation: %@", [error localizedDescription]);
//            }
//
//            for (CIFilter *filter in filterArray) {
//                [filter setValue:image forKey:kCIInputImageKey];
//                image = [filter outputImage];
//            }
//
//            iImage = [UIImage imageWithCIImage:image scale:1.0 orientation:(UIImageOrientation)rep.orientation];
//        }
//
//        bBusy = NO;
//    };
//
//    ALAssetsLibraryAccessFailureBlock failureblock  = ^(NSError *myerror)
//    {
//        NSLog(@"booya, cant get image - %@",[myerror localizedDescription]);
//    };
//
//    [_assetsLibrary assetForURL:urlImage
//                    resultBlock:resultblock
//                   failureBlock:failureblock];
//
//    while (bBusy)
//        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
//
    return iImage;
}

- (UIImage *)getImageFromAsset:(PHAsset *)asset type:(NSInteger)nType
{
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    //默认的是异步加载,这里选择了同步
    options.synchronous = YES;
    //PHImageManagerMaximumSize:获取原图,占用很大内存 建议不要使用
    CGSize tagetSize = PHImageManagerMaximumSize;
    
    if (nType == ASSET_PHOTO_THUMBNAIL)
        tagetSize = CGSizeMake(128.f, 128.f);
    else if (nType == ASSET_PHOTO_SCREEN_SIZE)
        tagetSize = PHImageManagerMaximumSize;
    else if (nType == ASSET_PHOTO_FULL_RESOLUTION)
    {
        tagetSize = PHImageManagerMaximumSize;
    }
    
    __block UIImage *targetImage = [UIImage new];
    [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:tagetSize contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info)
     {
         if ([[info valueForKey:@"PHImageResultIsDegradedKey"]integerValue]==0){
             if (result) {
                 targetImage = result;
             }
         } else {
             // Do something with the regraded image
         }
     }];
    
    return targetImage;
}

- (UIImage *)getImageAtIndex:(NSInteger)nIndex type:(NSInteger)nType
{
    return [self getImageFromAsset:(PHAsset *) _assetPhotos[nIndex] type:nType];
}

- (PHAsset *)getAssetAtIndex:(NSInteger)nIndex
{
    return _assetPhotos[nIndex];
}

@end
