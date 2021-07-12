//
//  File.swift
//  
//
//  Created by Александр Никитин on 11.07.2021.
//

import Foundation

public class FlightPlanParser {
    
    /**
     Parses an fpl file from the provided URL.
     */
    public static func parseFpl(source url: URL) throws -> [FlightplanItem] {
        let data = try Data(contentsOf: url)
        let result = FplParser().parse(data)
        return result
    }
    /**
     Parses an fpl file from the provided String.
     */
    public static func parseFpl(source string: String) -> [FlightplanItem] {
        guard let data = string.data(using: .utf8) else {return []}
        let result = FplParser().parse(data)
        return result
    }
    
    /**
     Encodes an array of ```FlightPlanItem```s into a file and returns it as String.
     - Parameters:
       - fpl: the flightplan to encode.
       - resolveIssues: Whether the parser should resolve issues when the flightplan has 2 ```FlightPlanItem```s with the same identifier but different other parameters, the parser will insert invisible unicode characters into the flightplan which would not impact how they look on the user's screen, but will be enough for the app to tell they are different waypoints.
     */
    public static func encodeFpl(_ fpl: [FlightplanItem], resolveIssues: Bool) -> String {
        /// *If you can't use codable on it, use line-by-line encoding*
        /// For real though it might not be the most efficient method, but you won't notice the efficiency
        
        // Step 1: prepare data
        
        // This is to find duplicates
        var routeItems = [RouteItem]()
        var flightPlanItemsDict = [String : FlightplanItem]()
        
        var resolvedIssuesCounter: Int = 0
        for index in 0..<fpl.count {
            var currentItem = fpl[index]
            if flightPlanItemsDict[currentItem.identifier] != nil
                && resolveIssues
                && flightPlanItemsDict[currentItem.identifier]!.hash != currentItem.hash {
                // Check for hashes is there in case it is just 2 identical waypoints
                
                // NSMutableString is much easier to work with
                var mutable = NSMutableString(string: currentItem.identifier)
                let strLen = mutable.length
                mutable.insert(String(repeating: "&#65279;", count: resolvedIssuesCounter/strLen + 1), at: resolvedIssuesCounter % strLen)
                currentItem.identifier = String(mutable)
                resolvedIssuesCounter += 1
            }
            let routeItem = RouteItem(identifier: currentItem.identifier, type: currentItem.type)
            routeItems.append(routeItem)
            flightPlanItemsDict[currentItem.identifier] = currentItem
        }
        
        var lines: [String] = [#"<?xml version="1.0" encoding="utf-8"?><flight-plan xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www8.garmin.com/xmlschemas/FlightPlan/v1">"#, "\t<waypoint-table>"]
        
        for item in flightPlanItemsDict.values {
            lines.append("\t\t<waypoint>")
            lines.append("\t\t\t<identifier>\(item.identifier)</identifier>")
            lines.append("\t\t\t<type>\(item.type)</type>")
            lines.append("\t\t\t<lat>\(item.latitude)</lat>")
            lines.append("\t\t\t<lon>\(item.longitude)</lon>")
            if item.elevation != nil {
                lines.append("\t\t\t<elevation>\(item.elevation!)</elevation>")
            }
            lines.append("\t\t</waypoint>")
        }
        lines.append("\t</waypoint-table>")
        
        lines.append("\t<route>")
        for index in 0..<routeItems.count {
            let item = routeItems[index]
            lines.append("\t\t<route-point>")
            lines.append("\t\t\t<waypoint-identifier>\(item.identifier)</waypoint-identifier>")
            lines.append("\t\t\t<waypoint-type>\(item.type)</waypoint-type>")
            lines.append("\t\t</route-point>")
        }
        lines.append("\t</route>")
        lines.append("\t</flight-plan>")
        let stringFile = lines.joined(separator: "\n")
        return stringFile
    }
    
    /**
     Encodes an array of ```FlightPlanItem```s into a file and writes to the provided URL.
     - Parameters:
       - fpl: the flightplan to encode.
       - resolveIssues: Whether the parser should resolve issues when the flightplan has 2 ```FlightPlanItem```s with the same identifier but different other parameters, the parser will insert invisible unicode characters into the flightplan which would not impact how they look on the user's screen, but will be enough for the app to tell they are different waypoints.
       - url: URL the encoded flight plan should be written to.
     */
    public static func encodeFpl(_ fpl: [FlightplanItem], resolveIssues: Bool, writeTo url: URL) throws {
        let strFile: String = encodeFpl(fpl, resolveIssues: resolveIssues)
        try strFile.write(to: url, atomically: true, encoding: .utf8)
    }
}
