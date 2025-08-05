//
//  ActivityChartTraceBuilder.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 04/10/2024.
//

import Foundation
import os
import SwiftUI

struct TimeDistance {
    var time: Date
    var distanceMeters: Double
}

struct ActivityChartTracePoint {
    var elapsedSeconds: Int                     // the time / x-axis value
    var distanceMeters: Double                  // distance travelled - alternative x-axis
    var primaryValue: Double                    // the foreground / primary trace value
    var primaryValueTimeSegmentAverage: Double  // eg. 10 min average for primary value
    var primaryValueDistanceSegmentAverage: Double  // eg. 10k average for primary value
    var timeSegmentMidpoint: Bool               // whether this is a midpoint of the time average block true / false
    var distanceSegmentMidpoint: Bool              // whether this is a midpoint of the distance average block true / false
    var backgroundValue: Double                 // the background / secondary trace value
    var scaledBackgroundValue: Double           // altitude trace, scaled by scale factor to fit as background to chart
}

struct ActivityChartTraceData: Identifiable {
    var id: String                                  // the name of the chart
    var colorScheme: Color                          // the colour scheme for the chart
    var displayPrimaryAverage: Bool                 // whether to display average anlaysis of primary value trace
    var timeXAxisMarks: [Int]                       // list of x-axis marks for time x-axis
    var timeXVisibleDomain: Int                     // width of visible domain when showing time-based graph
    var distanceXAxisMarks: [Int]                   // list of x-axis marks for distance x-axis
    var distanceXVisibleDomain: Int                 // width of visible domain when showing distance-based graph
    var primaryAxisMarks: [Int]                     // list of y-axis marks for the primary data as Integers
    var backgroundAxisMarks: [String]               // list of y-axis marks for the background data
    var backgroundDataScaleFactor: Int              // the scale factor used to scale the background data to the range of the primary data.
    var backgroundDataOffset: Int                   // the initial offest used to scale the background data to the range of the primary data.
    var tracePoints: [ActivityChartTracePoint]      // the list of trace points for primary and background data
}


// HRinput = trackPoints.map( {InputTraceDataPoint( time: $0.time, primaryValue: $0.heartRate, backgroundValue: $0.altitudeMeters)})
// build( inputTraceData: HRinput, defaultPrimaryMax: 150, backgroundAxisSuffix: "M" )
class ActivityChartTraceBuilder: NSObject {

    var defaultPrimaryMax: Double
    var backgroundAxisSuffix = ""
    var rollingAverageCount: Int = 1        // Whether to smooth readings with a rolling average over this number of values
    var averagesIncludeZeros: Bool
    
    let logger = Logger(subsystem: "com.RMurray.PulseWorkout",
                        category: "ActivityChartTraceBuilder")
    
    let NULL_TRACE: ActivityChartTraceData = ActivityChartTraceData(
        id: "",
        colorScheme: .gray,
        displayPrimaryAverage: false,
        timeXAxisMarks: [],
        timeXVisibleDomain: 10,
        distanceXAxisMarks: [],
        distanceXVisibleDomain: 10,
        primaryAxisMarks: [],
        backgroundAxisMarks: [],
        backgroundDataScaleFactor: 1,
        backgroundDataOffset: 0,
        tracePoints: [])
    
    init(defaultPrimaryMax: Double, backgroundAxisSuffix: String?, averagesIncludeZeros: Bool) {
    
        self.defaultPrimaryMax = defaultPrimaryMax
        self.backgroundAxisSuffix = backgroundAxisSuffix ?? ""
        self.averagesIncludeZeros = averagesIncludeZeros
        
    }
    
    func build(id: String,
               colorScheme: Color,
               displayPrimaryAverage: Bool,
               timeDistanceSeries: [TimeDistance],
               primaryDataSeries: [Double?],
               backgroundDataSeries: [Double?]) -> ActivityChartTraceData {
        
        var nonNillBackgroundDataSeries: [Double?]
        var smoothedPrimaryDataSeries: [Double?]
        
        if timeDistanceSeries.count != primaryDataSeries.count {
            logger.error("Primary data series different size to time series")
            return NULL_TRACE
        }

        if timeDistanceSeries.count != backgroundDataSeries.count {
            logger.error("background data series different size to time series")
            return NULL_TRACE
        }
        
        if timeDistanceSeries.count == 0 {
            logger.info("No data present for chart trace")
            return NULL_TRACE
        }
        
        nonNillBackgroundDataSeries = backgroundDataSeries
        if backgroundDataSeries.allSatisfy( {$0 == nil} ) {
            nonNillBackgroundDataSeries = backgroundDataSeries.map( {$0 ?? 0} )
        }
        
        smoothedPrimaryDataSeries = primaryDataSeries
        if rollingAverageCount > 1 {
            smoothedPrimaryDataSeries = rollingAverage(inputArray: primaryDataSeries.map( { $0 ?? 0 } ), rollCount: rollingAverageCount)
        }

        let numAxisSteps = 4
        
        // Get axis marks for the primary data series
        let maxPrimaryValue = smoothedPrimaryDataSeries.map( { $0 ?? 0 } ).max() ?? defaultPrimaryMax
        /// FIX USE 1/2/5 sometimes!!!
        let primaryAxisMarks = getAxisMarksForStepMultiple(max: maxPrimaryValue, stepMultiple: 10, intervals: numAxisSteps)

        // Get axis marks for background data series
        let maxBackgroundValue = backgroundDataSeries.map( { $0 ?? 0 } ).max() ?? 100
        let minBackgroundValue = backgroundDataSeries.map( { $0 ?? 0 } ).min() ?? 0
        let backgroundAxisMarkInts = getAxisMarksForStepMultiple(max: Double(maxBackgroundValue - minBackgroundValue), stepMultiple: 10, intervals: numAxisSteps)

        let backgroundAxisMarkStrings = backgroundAxisMarkInts.map({ String($0) + (backgroundAxisSuffix)})

        // Get scaling factor for background data series
        let backgroundDataScaleFactor = getScaleFactor(axisMarks1: primaryAxisMarks, axisMarks2: backgroundAxisMarkInts)
        
        // Note - already tested count > 0
        let startDate = timeDistanceSeries[0].time

        
        let primaryValueTimeSegmentAverageSeries = segmentAverageSeries(
            segmentSize: getAxisTimeGap(
                elapsedTimeSeries: timeDistanceSeries.map( { Int($0.time.timeIntervalSince(startDate)) })),
            xAxisSeries: timeDistanceSeries.map( { Double($0.time.timeIntervalSince(startDate)) }),
            inputSeries: smoothedPrimaryDataSeries,
            includeZeros: averagesIncludeZeros)

        let timeSegmentMidpointSeries: [Double] = segmentAverageSeries(
            segmentSize: getAxisTimeGap(
                elapsedTimeSeries: timeDistanceSeries.map( { Int($0.time.timeIntervalSince(startDate)) })),
            xAxisSeries: timeDistanceSeries.map( { Double($0.time.timeIntervalSince(startDate)) }),
            inputSeries: smoothedPrimaryDataSeries,
            includeZeros: averagesIncludeZeros,
            getMidpoints: true)
        
        let primaryValueDistanceSegmentAverageSeries: [Double] = segmentAverageSeries(
            segmentSize: getAxisMetersGap(
                distanceMetersSeries: timeDistanceSeries.map( { Int($0.distanceMeters) })),
            xAxisSeries: timeDistanceSeries.map( { Double($0.distanceMeters) }),
            inputSeries: smoothedPrimaryDataSeries,
            includeZeros: averagesIncludeZeros)
        
        let distanceSegmentMidpointSeries: [Double] = segmentAverageSeries(
            segmentSize: getAxisMetersGap(
                distanceMetersSeries: timeDistanceSeries.map( { Int($0.distanceMeters) })),
            xAxisSeries: timeDistanceSeries.map( { Double($0.distanceMeters) }),
            inputSeries: smoothedPrimaryDataSeries,
            includeZeros: averagesIncludeZeros,
            getMidpoints: true)
        
        // zip the 7 data series together and remove nil values
        let zippedSeries = zip(zip(zip(zip(zip(zip(timeDistanceSeries,
                                                   smoothedPrimaryDataSeries),
                                               nonNillBackgroundDataSeries),
                                           primaryValueTimeSegmentAverageSeries),
                                       primaryValueDistanceSegmentAverageSeries),
                                   timeSegmentMidpointSeries),
                               distanceSegmentMidpointSeries).map( { ($0.0.0.0.0.0.0, $0.0.0.0.0.0.1, $0.0.0.0.0.1, $0.0.0.0.1, $0.0.0.1, $0.0.1, $0.1) } )

        let nonNilSeries = zippedSeries.filter( {$0.1 != nil && $0.2 != nil} )



        let tracePoints = nonNilSeries.map(
            {ActivityChartTracePoint(elapsedSeconds: Int($0.0.time.timeIntervalSince(startDate)),
                                     distanceMeters: $0.0.distanceMeters,
                                     primaryValue: Double($0.1!),
                                     primaryValueTimeSegmentAverage: Double($0.3),
                                     primaryValueDistanceSegmentAverage: Double($0.4),
                                     timeSegmentMidpoint: Bool($0.5 == 1),
                                     distanceSegmentMidpoint: Bool($0.6 == 1),
                                     backgroundValue: Double($0.2!),
                                     scaledBackgroundValue: ((Double($0.2!) - minBackgroundValue) * backgroundDataScaleFactor))})


        return ActivityChartTraceData (
            id: id,
            colorScheme: colorScheme,
            displayPrimaryAverage: displayPrimaryAverage,
            timeXAxisMarks: getAxisTimeMarks(elapsedTimeSeries: tracePoints.map( { $0.elapsedSeconds })),
            timeXVisibleDomain: getAxisTimeGap(elapsedTimeSeries: tracePoints.map( { $0.elapsedSeconds })) * 2,
            distanceXAxisMarks: getAxisMetersMarks(distanceMetersSeries: tracePoints.map( { Int($0.distanceMeters) })),
            distanceXVisibleDomain: getAxisMetersGap(distanceMetersSeries: tracePoints.map( { Int($0.distanceMeters) })) * 2,
            primaryAxisMarks: primaryAxisMarks,
            backgroundAxisMarks: backgroundAxisMarkStrings,
            backgroundDataScaleFactor: Int(backgroundDataScaleFactor),
            backgroundDataOffset: Int(minBackgroundValue),
            tracePoints: tracePoints
        )

    }

}

