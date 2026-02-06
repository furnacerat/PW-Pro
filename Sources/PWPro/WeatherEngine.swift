import SwiftUI

struct Job: Identifiable {
    let id = UUID()
    let address: String
    let surfaceType: SurfaceType
    let customerName: String
    let scheduledTime: String
    
    // Mock localized weather for the job site
    var windSpeed: Double
    var rainChance: Double
}

enum WeatherSafetyStatus {
    case optimal
    case suboptimal
    case dangerous
    
    var color: Color {
        switch self {
        case .optimal: return Theme.emerald500
        case .suboptimal: return Theme.amber500
        case .dangerous: return Theme.red500
        }
    }
    
    var icon: String {
        switch self {
        case .optimal: return "checkmark.seal.fill"
        case .suboptimal: return "exclamationmark.triangle.fill"
        case .dangerous: return "xmark.octagon.fill"
        }
    }
}

class WeatherEngine {
    static func analyze(job: Job) -> (status: WeatherSafetyStatus, recommendation: String) {
        let wind = job.windSpeed
        let rain = job.rainChance
        
        switch job.surfaceType {
        case .roof:
            if wind > 12 {
                return (.dangerous, "High Wind Warning: Dangerous for Roof Work & Overspray Risk.")
            } else if rain > 30 {
                return (.suboptimal, "Rain Risk: Slippery surfaces and chemical dilution possible.")
            }
            
        case .siding:
            if wind > 20 {
                return (.suboptimal, "Windy: Use caution with high-reach wands and overspray.")
            } else if rain > 40 {
                return (.suboptimal, "Suboptimal: Rain may affect chemical dwell time.")
            }
            
        case .concrete:
            if rain > 60 {
                return (.suboptimal, "Heavy Rain: Surface cleaning effectiveness reduced.")
            }
            
        default:
            if wind > 25 || rain > 70 {
                return (.suboptimal, "Adverse Weather: Use professional judgment.")
            }
        }
        
        return (.optimal, "Optimal Conditions for \(job.surfaceType.rawValue).")
    }
    
    static func analyze(scheduledJob: ScheduledJob) -> (status: WeatherSafetyStatus, recommendation: String) {
        let wind = scheduledJob.windSpeed
        let rain = scheduledJob.rainChance
        
        switch scheduledJob.surfaceType {
        case .roof:
            if wind > 12 {
                return (.dangerous, "High Wind Warning: Dangerous for Roof Work & Overspray Risk.")
            } else if rain > 30 {
                return (.suboptimal, "Rain Risk: Slippery surfaces and chemical dilution possible.")
            }
            
        case .siding:
            if wind > 20 {
                return (.suboptimal, "Windy: Use caution with high-reach wands and overspray.")
            } else if rain > 40 {
                return (.suboptimal, "Suboptimal: Rain may affect chemical dwell time.")
            }
            
        case .concrete:
            if rain > 60 {
                return (.suboptimal, "Heavy Rain: Surface cleaning effectiveness reduced.")
            }
            
        default:
            if wind > 25 || rain > 70 {
                return (.suboptimal, "Adverse Weather: Use professional judgment.")
            }
        }
        
        return (.optimal, "Optimal Conditions for \(scheduledJob.surfaceType.rawValue).")
    }
}

// Mock Data for the day
struct MockData {
    static let todayJobs: [Job] = [
        Job(address: "123 Maple St, Seattle", 
            surfaceType: .roof, 
            customerName: "Alice Johnson", 
            scheduledTime: "08:30 AM", 
            windSpeed: 15.0, 
            rainChance: 10.0),
        
        Job(address: "456 Oak Ave, Bellevue", 
            surfaceType: .siding, 
            customerName: "Bob Smith", 
            scheduledTime: "11:00 AM", 
            windSpeed: 8.0, 
            rainChance: 45.0),
        
        Job(address: "789 Pine Ln, Redmond", 
            surfaceType: .concrete, 
            customerName: "Charlie Brown", 
            scheduledTime: "02:30 PM", 
            windSpeed: 5.0, 
            rainChance: 5.0)
    ]
}
