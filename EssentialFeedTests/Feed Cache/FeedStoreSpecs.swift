//
//  FeedStoreSpecs.swift
//  EssentialFeedTests 
//
//  Created by Karthik K Manoj on 15/10/24.
//

import Foundation

protocol FeedStoreSpecs {
    func test_retreive_deliversEmptyOnEmptyCache()
    
    func test_retreive_hasNoSideEffectsOnEmptyCache()
    
    func test_retreive_afterInsertingToEmptyCache_deliversInsertedValues()
    
    func test_retreive_deliversFoundValuesOnNonEmptyCache()
    
    func test_insert_overridesPreviouslyInsertedCacheValues()
    
    func test_delete_hasNoSideEffectOnEmptyCache()
    
    func test_delete_deletesPreviouslyInsertedCache()
     
    func test_storeSideEffects_runSerially()
}

protocol FailableRetrieveFeedStoreSpecs: FeedStoreSpecs {
    func test_retrieve_deliversFailureOnRetrievalError()
    func test_retrieve_hasNoSideEffectsOnFailure()
}

protocol FailableInsertFeedStoreSpecs:FeedStoreSpecs {
    func test_insert_deliversErrorOnInsertionFailure()
    func test_insert_hasNoSideEffectOnInsertionFailure()
}

protocol FailableDeleteFeedStoreSpecs: FeedStoreSpecs {
    func test_delete_deliversErrorOnDeletionError()
    func test_delete_hasNoSideEffectOnDeletionError()
}

typealias FailableFeedStore = FailableRetrieveFeedStoreSpecs & FailableInsertFeedStoreSpecs & FailableDeleteFeedStoreSpecs
