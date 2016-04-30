//
//  HCPublicMusictablesModel.m
//  LittleFrog
//
//  Created by huangcong on 16/4/23.
//  Copyright © 2016年 HuangCong. All rights reserved.
//

#import "HCPublicMusictablesModel.h"

@implementation HCPublicMusictablesModel
+ (NSArray *)mj_allowedPropertyNames
{
    return @[@"listid",@"listenum",@"title",@"pic_300",@"pic_big",@"author",@"album_id"];
}
@end
