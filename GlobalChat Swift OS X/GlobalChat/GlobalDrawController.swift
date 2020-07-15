//
//  GlobalDrawController.swift
//  GlobalChat
//
//  Created by Jonathan Silverman on 7/9/20.
//  Copyright © 2020 Jonathan Silverman. All rights reserved.
//

import Cocoa
import CoreGraphics

class GlobalDrawController: NSViewController {
    
    @IBOutlet weak var drawing_view: LineDrawer!
    
    var gcc: GlobalChatController?
    
    var points_size : Int?
    
    var loaded = false

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        print("viewDidLoad: gdc")
//        drawing_view.pen_width = CGFloat(5.0)
        loaded = true
        drawing_view.gdc = self
    }
    
    func brushBigger() {
        if(loaded) {
            drawing_view.pen_width = CGFloat(drawing_view.pen_width + 1.0)
        }
    }
    
    func brushSmaller() {
        if(loaded) {
            if(drawing_view.pen_width > 1) {
                drawing_view.pen_width = CGFloat(drawing_view.pen_width - 1.0)
            }
        }
    }
    
    
    func saveImage() {
        let savePanel = NSSavePanel()
        savePanel.allowedFileTypes = ["png"]
        savePanel.begin { (result) in
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                let path = savePanel.url!.path
                
                let image = self.drawing_view.imageRepresentation()
                
                let imgRep = image.representations[0] as! NSBitmapImageRep
                let data = imgRep.representation(using: NSBitmapImageRep.FileType.png, properties: [:])
                if let data = data {
                    NSData(data: data).write(toFile: path, atomically: false)
                }


            }
        }
    }

    
}

class LineDrawer : NSImageView {
    var newLinear = NSBezierPath()
    
    
    var points : [[String : Any]] = [] {
        didSet {
            checkIfTooManyPointsIn(&points)
        }
    }
    
    var nameHash : [String : Int] = [:] // which layer is this handle on
    
    var layerOrder : [String] = [] // which order to draw layers
    
    var layers : [String : Any] = [:] // which points are in a layer
    
    var points_total : Int = 0
    
    var gdc : GlobalDrawController = GlobalDrawController()
    
//    var username : String = ""
    
    var scribbling : Bool = false
    var pen_color : NSColor = NSColor.black.usingColorSpace(NSColorSpace.deviceRGB)!
    var pen_width : CGFloat = CGFloat(1)
    
    var flattenedImage: NSImage?
    
    public func clearCanvas() {
        points.removeAll()
        layerOrder.removeAll()
        layers.removeAll()
        nameHash.removeAll()
        points_total = 0
        needsDisplay = true
    }
    
    
    public func addClick(_ x: CGFloat, y: CGFloat, dragging: Bool, red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat, width: CGFloat, clickName: String) {
        
//        print("num points \(points.count)")
        (self.window?.contentViewController as! GlobalDrawController).title = "\(points_total)/\(gdc.points_size! - 1)"
        
        var point : [String : Any] = [:]
        point["x"] = x
        point["y"] = y
        point["dragging"] = dragging
        point["red"] = red
        point["green"] = green
        point["blue"] = blue
        point["alpha"] = alpha
        point["width"] = width
        point["clickName"] = clickName
        points.append(point)
        points_total = points_total + 1
        
        var layerName : String = ""
        
        if(nameHash[clickName] == nil) {
            let layer = 0
            nameHash[clickName] = layer
            layerName = "\(clickName)_\(layer)"
            let layerArray : [[String : Any]] = []
            layers[layerName] = layerArray
        } else {
            if(dragging == false) {
                let layer = nameHash[clickName]! + 1
                nameHash[clickName] = layer
                layerName = "\(clickName)_\(layer)"
                let layerArray : [[String : Any]] = []
                layers[layerName] = layerArray
            } else {
                let layer = nameHash[clickName]!
                layerName = "\(clickName)_\(layer)"
            }
        }
        
        var tempLayers = layers[layerName] as! [[String : Any]]
        tempLayers.append(point)
        layers[layerName] = tempLayers
        
        if(!layerOrder.contains(layerName)) {
            layerOrder.append(layerName)
        }
        
    }
    
    func drawLineTo(_ lastPoint : CGPoint, _ endPoint : CGPoint, _ penColor : NSColor, _ penWidth : CGFloat) {
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.setStrokeColor(penColor.cgColor)
        context.setLineCap(.round)
        context.setLineWidth(penWidth)
        context.move(to: lastPoint)
        context.addLine(to: endPoint)
        context.strokePath()
        
    }
    
    func checkIfTooManyPointsIn(_ line: inout [[String : Any]]) {
        let maxPoints = 200
        if line.count > maxPoints {
//            print("too many points")
            flattenedImage = self.imageRepresentation()

            // we leave one point to ensure no gaps in drawing
            line.removeAll()
            layerOrder.removeAll()
            layers.removeAll()
            nameHash.removeAll()
        }
    }
    
    func flattenImage() {
        flattenedImage = self.imageRepresentation()
        points.removeAll()
        layerOrder.removeAll()
        layers.removeAll()
        nameHash.removeAll()
    }
    
    
    func redraw() {
        NSColor.white.setFill() // allow configuration of this later
        bounds.fill()
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        if let image = flattenedImage {
            var imageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
            let imageRef = image.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)!
            context.draw(imageRef, in: self.frame)
        }
        
        
        for layer in layerOrder {
            let layerArray = layers[layer] as! [[String : Any]]
            for i in 0...layerArray.count - 1 {

                let thisObj = layerArray[i] as [String : Any]
                let thisPoint : CGPoint = CGPoint(x: thisObj["x"] as! CGFloat, y: thisObj["y"] as! CGFloat)
                let red = thisObj["red"] as! CGFloat
                let green = thisObj["green"] as! CGFloat
                let blue = thisObj["blue"] as! CGFloat
                let alpha = thisObj["alpha"] as! CGFloat
                let penColor : NSColor = NSColor.init(red: red, green: green, blue: blue, alpha: alpha)
                let penWidth = thisObj["width"] as! CGFloat
                if(thisObj["dragging"] as! Bool && i > 0) {
                    let lastObj = layerArray[i - 1] as [String : Any]
                    let lastPoint : CGPoint = CGPoint(x: lastObj["x"] as! CGFloat, y: lastObj["y"] as! CGFloat)
                    drawLineTo(lastPoint, thisPoint, penColor, penWidth)
                } else {
                    var drawPoint = NSPoint()
                    drawPoint.x = thisPoint.x - 1
                    drawPoint.y = thisPoint.y
                    drawLineTo(thisPoint, drawPoint, penColor, penWidth)
                }
            }
        }
        
    }

    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let objectFrame: NSRect = self.frame
        if self.needsToDraw(objectFrame) {
            // drawing code for object
            redraw()
        }
    }

    override func mouseDown(with event: NSEvent) {
        
        
        if points_total < gdc.points_size! - 1 {
            return
        }
        
        super.mouseDown(with: event)
        
        scribbling = true
        
        var lastPt = convert(event.locationInWindow, from: nil)
        lastPt.x -= frame.origin.x
        lastPt.y -= frame.origin.y
        
        addClick(lastPt.x, y: lastPt.y, dragging: false, red: pen_color.redComponent, green: pen_color.greenComponent, blue: pen_color.blueComponent, alpha: pen_color.alphaComponent, width: pen_width, clickName: gdc.gcc!.handle)
        
        send_point(lastPt.x, y: lastPt.y, dragging: false, red: pen_color.redComponent, green: pen_color.greenComponent, blue: pen_color.blueComponent, alpha: pen_color.alphaComponent, width: pen_width, clickName: gdc.gcc!.handle)
        
        needsDisplay = true
        
    }

    override func mouseDragged(with event: NSEvent) {
        if points_total < gdc.points_size! - 1 {
            return
        }
        
        super.mouseDragged(with: event)
        var newPt = convert(event.locationInWindow, from: nil)
        newPt.x -= frame.origin.x
        newPt.y -= frame.origin.y
        
        addClick(newPt.x, y: newPt.y, dragging: true, red: pen_color.redComponent, green: pen_color.greenComponent, blue: pen_color.blueComponent, alpha: pen_color.alphaComponent, width: pen_width, clickName: gdc.gcc!.handle)
        
        
        send_point(newPt.x, y: newPt.y, dragging: true, red: pen_color.redComponent, green: pen_color.greenComponent, blue: pen_color.blueComponent, alpha: pen_color.alphaComponent, width: pen_width, clickName: gdc.gcc!.handle)

        needsDisplay = true
        
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        scribbling = false
        flattenImage()
        
    }
    
    
    func send_point(_ x: CGFloat, y: CGFloat, dragging: Bool, red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat, width: CGFloat, clickName: String) {
        let gdc = self.window?.contentViewController as! GlobalDrawController
        var point : [String] = []
        point.append(String(x.description))
        point.append(String(y.description))
        point.append(String(dragging.description))
        point.append(String(red.description))
        point.append(String(green.description))
        point.append(String(blue.description))
        point.append(String(alpha.description))
        point.append(String(width.description))
        point.append(String(gdc.gcc!.chat_token))
        gdc.gcc?.send_message("POINT", args: point)
    }
    
    func imageRepresentation() -> NSImage {
        let mySize = bounds.size
        let imgSize = NSMakeSize(mySize.width, mySize.height)

        let bir = bitmapImageRepForCachingDisplay(in: bounds)
        bir?.size = imgSize
        if let bir = bir {
            cacheDisplay(in: bounds, to: bir)
        }

        let image = NSImage(size: imgSize)
        if let bir = bir {
            image.addRepresentation(bir)
        }
        return image
    }
    
}
