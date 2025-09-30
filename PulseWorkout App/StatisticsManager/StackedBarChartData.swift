//
//  StackedBarChartData.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 30/09/2025.
//

import Foundation
import HealthKit
import SwiftUI

enum StackedBarType {
    case powerZone
    case activityType
}

struct StackedBarChartData {

    struct SubCategory {
        var id: Int
        var label: String
        var color: Color
    }
    struct DataPoint: Identifiable {
        let id = UUID()
        var category: String?
        var subCategory: Int?
        var value: Double
        var formattedValue: String
    }

    
    var propertyName: String
    var subCategories: [SubCategory]
    var dataPoints: [DataPoint]
    
    var totalsByCategory: [DataPoint]           /// Totals for each category - summing across values in subcategories
    var totalsBySubcategory: [DataPoint]        /// Total for each subcategory  - summing across values in categories
    
    var stackedBarType: StackedBarType
    var totalName: String
    var total: Double

    func formattedTotal() -> String {
        return formattedPropertyValue(propertyName, value: total, shortForm: false)
    }
    
    
    /// Initialise for a property name
    init(propertyName: String) {
        self.propertyName = propertyName
        self.stackedBarType = PropertyViewParamaters[propertyName]?.stackedBarType ?? .powerZone

        dataPoints = []
        subCategories = []
        totalsByCategory = []
        totalsBySubcategory = []
        totalName = PropertyViewParamaters[propertyName]?.totalLabel ?? "Total"
        total = 0

    }
    
    
    init(copyFrom: StackedBarChartData, filterCategories: [String] = []) {
        
        propertyName = copyFrom.propertyName
        subCategories = copyFrom.subCategories
        dataPoints = copyFrom.dataPoints
        
        totalsByCategory = copyFrom.totalsByCategory
        totalsBySubcategory = copyFrom.totalsBySubcategory
        
        stackedBarType = copyFrom.stackedBarType
        totalName = copyFrom.totalName
        total = copyFrom.total
        
        if filterCategories.count > 0 {
            dataPoints = dataPoints.filter( {filterCategories.contains($0.category ?? "")})
            totalsByCategory = totalsByCategory.filter( {filterCategories.contains($0.category ?? "")})
            total = dataPoints.reduce(0) { result, dataPoint
                in
                result + dataPoint.value}
            setSubcategories()
            totalsBySubcategory = subCategories.map(
                {subCat in
                    let total = dataPoints.filter({$0.subCategory == subCat.id}).reduce(0) { result, dataPoint in result + dataPoint.value}
                    
                    return DataPoint(subCategory: subCat.id,
                                     value: total,
                                     formattedValue: formattedPropertyValue(propertyName,
                                                                            value: total,
                                                                            shortForm: false))
                }
            )

        }
        
    }
    
    // Set the stack data categories for the data in the dataPoints
    mutating func setSubcategories() {

        switch stackedBarType {
        case .powerZone:
            subCategories = [SubCategory(id: 0, label: "Low Aerobic", color: .blue),
                             SubCategory(id: 1, label: "High Aerobic", color: .green),
                             SubCategory(id: 2, label: "Anaerobic", color: .orange)]
        case .activityType:
            let uniqueCategories = Set(dataPoints.filter({$0.subCategory != nil}).map({$0.subCategory!})).sorted()
            subCategories = uniqueCategories.map({SubCategory(id: $0,
                                                              label: HKWorkoutActivityType(rawValue: UInt($0))?.name ?? "Error",
                                                              color: HKWorkoutActivityType(rawValue: UInt($0))?.colorRepresentation ?? Color.red)})
        }

    }
    
    
    // Add a datapoint
    mutating func add(category: String, subCategory: Int?, value: Double) {
        dataPoints.append(DataPoint(category: category,
                                    subCategory: subCategory,
                                    value: value,
                                    formattedValue: formattedPropertyValue(propertyName,
                                                                           value: value,
                                                                           shortForm: false)))
        

        if subCategory != nil {
            if let i = totalsBySubcategory.firstIndex(where: {$0.subCategory == subCategory} ) {
                totalsBySubcategory[i].value += value
                totalsBySubcategory[i].formattedValue = formattedPropertyValue(propertyName,
                                                                               value: totalsBySubcategory[i].value,
                                                                               shortForm: false)
            } else {
                totalsBySubcategory.append(DataPoint(subCategory: subCategory,
                                                     value: value,
                                                     formattedValue: formattedPropertyValue(propertyName,
                                                                                            value: value,
                                                                                            shortForm: false)))
            }
            

        }
        

        // Now update category totals
        if let i = totalsByCategory.firstIndex(where: {$0.category == category} ) {
            totalsByCategory[i].value += value
            totalsByCategory[i].formattedValue = formattedPropertyValue(propertyName,
                                                                        value: totalsByCategory[i].value,
                                                                        shortForm: true)
        } else {
            totalsByCategory.append(DataPoint(category: category,
                                              value: value,
                                              formattedValue: formattedPropertyValue(propertyName,
                                                                                     value: value,
                                                                                     shortForm: true)))
        }
            



        
        total += value
        
        setSubcategories()
    }
    
    mutating func setAsWeeklyAverage(divisorDays: Double) {
        
        totalName = "Weekly Average"
        total = total / divisorDays
        totalsBySubcategory = totalsBySubcategory.map( {DataPoint(subCategory: $0.subCategory,
                                                                  value: $0.value / divisorDays,
                                                                  formattedValue: formattedPropertyValue(propertyName,
                                                                                                         value: $0.value / divisorDays,
                                                                                                         shortForm: false)) } )

        
    }
    
    
    // return list of valid indexes for the array of data points
    func dataPointIndices() -> [Int] {
        return Array(dataPoints.indices)
    }
    
    // return category for the datapoint at the index
    func category(index: Int) -> String {
        if index < dataPoints.count {
            return dataPoints[index].category ?? "Error"
        }
        return "Error"
    }
    
    // return value for the datapoint at the index
    func value(index: Int) -> Double {
        if index < dataPoints.count {
            return dataPoints[index].value
        }
        return 0
    }
    
    /// Get category colour from index
    func categoryColor(index: Int) -> Color {
        if index < dataPoints.count {
            let cat = dataPoints[index].subCategory
            if let stackDataCat = subCategories.first(where: {$0.id == cat}) {
                return stackDataCat.color
            }
        }
        return Color.red
    }
    
    /// Get category colour from subCategory
    func categoryColor(subCategory: Int?) -> Color {
        
        if let stackDataCat = subCategories.first(where: {$0.id == subCategory}) {
            return stackDataCat.color
        }
        return Color.red
    }
    
    /// Get category label from subCategory
    func subCategoryLabel(subCategory: Int?) -> String {
        
        if let subCategory = subCategories.first(where: {$0.id == subCategory}) {
            return subCategory.label
        }
        return ""
    }
    
    func allCategoryLabels() -> [String] {
        return subCategories.map( {$0.label})
    }

    func allCategoryColors() -> [Color] {
        return subCategories.map( {$0.color})
    }
    
    func formattedTotalForCategory(category: String) -> String {
        return totalsByCategory.first(where: {$0.category == category})?.formattedValue ?? "0"
    }
    
}

