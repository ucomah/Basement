import UIKit
import Basement

let formatter: DateFormatter = {
    let f = DateFormatter()
    f.timeStyle = .long
    return f
}()

final class Color: Object {
    @Persisted
    var time: TimeInterval = Date().timeIntervalSinceReferenceDate
    @Persisted
    var colorR = Double.random(in: 0...1.0)
    @Persisted
    var colorG = Double.random(in: 0...1.0)
    @Persisted
    var colorB = Double.random(in: 0...1.0)
    
    var color: UIColor {
        UIColor(red: CGFloat(colorR), green: CGFloat(colorG), blue: CGFloat(colorB), alpha: 1.0)
    }
}

final class TickCounter: Object {
    @Persisted(primaryKey: true)
    var id = UUID().uuidString
    @Persisted
    var ticks: Int = 0
}
