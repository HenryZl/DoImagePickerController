//
//  AssetHelper.h
//  DoImagePickerController
//
//  Created by Donobono on 2014. 1. 23..
//


#define ASSETHELPER [AssetHelper sharedAssetHelper]

#define ASSET_PHOTO_THUMBNAIL 0
#define ASSET_PHOTO_SCREEN_SIZE 1
#define ASSET_PHOTO_FULL_RESOLUTION 2

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>


@interface AssetHelper : NSObject

- (void)initAsset;

//@property (nonatomic, strong)   ALAssetsLibrary            *assetsLibrary;
@property(nonatomic, strong) PHPhotoLibrary *phphotoLibrary;

@property(nonatomic, strong) NSMutableArray *assetPhotos;
@property(nonatomic, strong) NSMutableArray *assetGroups;

@property(readwrite) BOOL bReverse;

+ (AssetHelper *)sharedAssetHelper;

// get album list from asset
- (void)getGroupList:(void (^)(NSArray *))result;
// get photos from specific album with ALAssetsGroup object
- (void)getPhotoListOfGroup:(PHCollection *)alGroup result:(void (^)(NSArray *))result;
// get photos from specific album with index of album array
- (void)getPhotoListOfGroupByIndex:(NSInteger)nGroupIndex result:(void (^)(NSArray *))result;
// get photos from camera roll
- (void)getSavedPhotoList:(void (^)(NSArray *))result error:(void (^)(NSError *))error;

- (NSInteger)getGroupCount;
- (NSInteger)getPhotoCountOfCurrentGroup;
- (NSDictionary *)getGroupInfo:(NSInteger)nIndex;

- (void)clearData;

// utils
- (UIImage *)getCroppedImage:(NSURL *)urlImage;
- (UIImage *)getImageFromAsset:(PHAsset *)asset type:(NSInteger)nType;
- (UIImage *)getImageAtIndex:(NSInteger)nIndex type:(NSInteger)nType;
- (PHAsset *)getAssetAtIndex:(NSInteger)nIndex;

@end
