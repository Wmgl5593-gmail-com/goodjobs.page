// clang-format off

//
//  Copyright (c) 2016 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

// clang-format on

#import "FirebaseCollectionViewDataSource.h"

@import FirebaseDatabase;

@implementation FirebaseCollectionViewDataSource

#pragma mark - FirebaseDataSource initializer methods

- (instancetype)initWithQuery:(FIRDatabaseQuery *)query
                         view:(UICollectionView *)collectionView
                 populateCell:(UICollectionViewCell *(^)(UICollectionView *,
                                                         NSIndexPath *,
                                                         FIRDataSnapshot *))populateCell {
  FirebaseArray *array = [[FirebaseArray alloc] initWithQuery:query];
  self = [super initWithArray:array];
  if (self) {
    _collectionView = collectionView;
    _populateCellAtIndexPath = populateCell;
  }
  return self;
}

#pragma mark - FirebaseArrayDelegate methods

- (void)array:(FirebaseArray *)array didAddObject:(id)object atIndex:(NSUInteger)index {
  [self.collectionView
      insertItemsAtIndexPaths:@[ [NSIndexPath indexPathForItem:index inSection:0] ]];
}

- (void)array:(FirebaseArray *)array didChangeObject:(id)object atIndex:(NSUInteger)index {
  [self.collectionView
      reloadItemsAtIndexPaths:@[ [NSIndexPath indexPathForItem:index inSection:0] ]];
}

- (void)array:(FirebaseArray *)array didRemoveObject:(id)object atIndex:(NSUInteger)index {
  [self.collectionView
      deleteItemsAtIndexPaths:@[ [NSIndexPath indexPathForItem:index inSection:0] ]];
}

- (void)array:(FirebaseArray *)array didMoveObject:(id)object
    fromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex {
  [self.collectionView moveItemAtIndexPath:[NSIndexPath indexPathForItem:fromIndex inSection:0]
                               toIndexPath:[NSIndexPath indexPathForItem:toIndex inSection:0]];
}

#pragma mark - UICollectionViewDataSource methods

- (nonnull UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView
                          cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
  FIRDataSnapshot *snap = [self.items objectAtIndex:indexPath.row];

  UICollectionViewCell *cell = self.populateCellAtIndexPath(collectionView, indexPath, snap);

  return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(nonnull UICollectionView *)collectionView {
  return 1;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
  return self.count;
}

@end

@implementation UICollectionView (FirebaseCollectionViewDataSource)

- (FirebaseCollectionViewDataSource *)bindToQuery:(FIRDatabaseQuery *)query
                                     populateCell:(UICollectionViewCell *(^)(UICollectionView *,
                                                                             NSIndexPath *,
                                                                             FIRDataSnapshot *))populateCell {
  FirebaseCollectionViewDataSource *dataSource =
    [[FirebaseCollectionViewDataSource alloc] initWithQuery:query view:self populateCell:populateCell];
  self.dataSource = dataSource;
  return dataSource;
}

@end
