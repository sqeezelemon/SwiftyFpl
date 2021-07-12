//
//  File.swift
//
//
//  Created by Александр Никитин on 11.07.2021.
//

import Foundation

/// XMLParser delegate that also parses the data using parse(_ data: Data) method
internal class FplParser: NSObject, XMLParserDelegate {
    
    private var buffer: String = ""
    private var currentFlightPlanItem = FlightplanItem()
    private var currentRouteItem = RouteItem()
    private var flightPlanItems = [FlightplanItem]()
    private var routeItems = [RouteItem]()
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        buffer = ""
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        buffer.append(string)
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        switch elementName {
        // These tags are exclusive to <route>
        case "waypoint-identifier":
            currentRouteItem.identifier = buffer
        case "waypoint-type":
            currentRouteItem.type = buffer
            
        // These tages are exclusive to <waypoint-table>
        case "identifier":
            currentFlightPlanItem.identifier = buffer
        case "type":
            currentFlightPlanItem.type = buffer
        case "lat":
            if let num = Float(buffer) {
                currentFlightPlanItem.latitude = num
            }
        case "lon":
            if let num = Float(buffer) {
                currentFlightPlanItem.longitude = num
            }
        case "elevation":
            currentFlightPlanItem.elevation = Float(buffer)
        
        // Tags for when a <waypoint> or <route-point> ends
        case "waypoint":
            flightPlanItems.append(currentFlightPlanItem)
            currentFlightPlanItem = FlightplanItem()
        case "route-point":
            routeItems.append(currentRouteItem)
            currentRouteItem = RouteItem()
            
        default:
            return
        }
    }
    
    func parse(_ data: Data) -> [FlightplanItem] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        
        var flightPlanItemsDict = [String : FlightplanItem]()
        for item in flightPlanItems {
            if flightPlanItemsDict[item.identifier] == nil {
                flightPlanItemsDict[item.identifier] = item
            }
        }
        
        var result = [FlightplanItem]()
        for routeItemIndex in 0..<routeItems.count {
            let routeItem = routeItems[routeItemIndex]
            if let flightPlanItem = flightPlanItemsDict[routeItem.identifier] {
                result.append(flightPlanItem)
            }
        }
        
        return result
    }
    
}
