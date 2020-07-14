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
    
    var loaded = false

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        print("viewDidLoad: gdc")
//        drawing_view.pen_width = CGFloat(5.0)
        loaded = true
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
    
    @objc func colorDidChange(sender:AnyObject) {
        if let cp = sender as? NSColorPanel {
            print(cp.color)
            if(drawing_view == nil) {
                self.loadView()
            }
            drawing_view.pen_color = cp.color
            
        }
    }
    
    @IBAction func changeColor(_ sender : Any) {
        let cp = NSColorPanel.shared
        cp.setTarget(self)
        cp.setAction(#selector(self.colorDidChange(sender:)))
        cp.makeKeyAndOrderFront(self)
        cp.isContinuous = true
        cp.showsAlpha = true
    }
    
    func saveImage() {
        let savePanel = NSSavePanel()
        savePanel.allowedFileTypes = ["png"]
        savePanel.begin { (result) in
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                let path = savePanel.url!.path
                
                let image = self.drawing_view.imageRepresentation() as! NSImage
                
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
    
    
    var points : [[String : Any]] = []
    
    var nameHash : [String : Int] = [:] // which layer is this handle on
    
    var layerOrder : [String] = [] // which order to draw layers
    
    var layers : [String : Any] = [:] // which points are in a layer
    
//    var username : String = ""
    
    var scribbling : Bool = false
    var pen_color : NSColor = NSColor.black.usingColorSpace(NSColorSpace.deviceRGB)!
    var pen_width : CGFloat = CGFloat(1)
    
//    override init(frame frameRect: NSRect) {
//        super.init(frame: frameRect)
//        let gdc = self.window?.contentViewController as! GlobalDrawController
//        gdc.gcc?.send_message("GETPOINTS", args: [])
//    }
    
    
    public func addClick(_ x: CGFloat, y: CGFloat, dragging: Bool, red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat, width: CGFloat, clickName: String) {
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
    
    
    func redraw() {
        NSColor.white.setFill() // allow configuration of this later
        bounds.fill()
        
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
        let gdc = self.window?.contentViewController as! GlobalDrawController
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
        let gdc = self.window?.contentViewController as! GlobalDrawController
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
    
    func imageRepresentation() -> Any! {
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
