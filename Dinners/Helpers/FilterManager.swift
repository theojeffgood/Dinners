//
//  Filtermanager.swift
//  FryDay
//
//  Created by Theo Goodman on 3/1/24.
//

import Foundation
import CoreData
import CloudKit

class FilterManager: NSObject, ObservableObject {
    
    @Published var appliedFilters: Set<Category>
    var purchasedFilters: [Category]
    var filterIsActive: Bool
    
    var allFilters: [Category]{
        didSet{
            let purchasedFilters = allFilters.filter({ $0.isPurchased })
            appliedFilters = Set(purchasedFilters)
        }
    }
    private var allPurchases: [Purchase]{
        didSet{
            for purchase in allPurchases{
                if let householdPurchase = allFilters.filter({ $0.id == purchase.categoryId && !$0.isPurchased }).first{
                    appliedFilters.insert(householdPurchase)
                }
            }
        }
    }
    
    private let categoryController: NSFetchedResultsController<Category>
    private let purchaseController: NSFetchedResultsController<Purchase>
    private let context: NSManagedObjectContext
    
    init(managedObjectContext: NSManagedObjectContext) {
        context = managedObjectContext
        categoryController = NSFetchedResultsController(fetchRequest: Category.fetchRequest(),
                                                       managedObjectContext: context,
                                                       sectionNameKeyPath: nil, cacheName: nil)
        
        purchaseController   = NSFetchedResultsController(fetchRequest: Purchase.fetchRequest(),
                                                       managedObjectContext: context,
                                                       sectionNameKeyPath: nil, cacheName: nil)
        
        allFilters = []
        allPurchases = []
        purchasedFilters = []
        appliedFilters = []
        filterIsActive = false
        super.init()
        
        categoryController.delegate = self
        purchaseController.delegate = self
        
        setValues()
    }
    
    func setValues(){
        do {
            try categoryController.performFetch() // this must come first for applying purchases to work
            try purchaseController.performFetch()
            
            allFilters   = categoryController.fetchedObjects ?? []
            allPurchases = purchaseController.fetchedObjects ?? []
            
        } catch { print("failed to fetch items!") }
    }
}

extension FilterManager: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        if case let categories = controller.fetchedObjects as? [Category],
           categories?.isEmpty == false{
            allFilters = categories!
        }
        
        if case let purchases = controller.fetchedObjects as? [Purchase],
           purchases?.isEmpty == false{
            allPurchases = purchases!
        }
    }
}

extension FilterManager{
    func toggleFilter(_ filter: Category) {
        filterIsActive.toggle()
        
        switch filterIsActive {
        case true:
            appliedFilters = [filter]
            
        case false:
            let purchasedFilters = allFilters.filter({ $0.isPurchased })
            appliedFilters = Set(purchasedFilters)
            
            for purchase in allPurchases{
                if let householdPurchase = allFilters.filter({ $0.id == purchase.categoryId && !$0.isPurchased }).first{
                    appliedFilters.insert(householdPurchase)
                }
            }
        }
    }
}
