import Foundation
import SwiftUI

/// ViewModel for birth data collection
@Observable
class BirthDataViewModel {
    // MARK: - Form State
    var dateOfBirth = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    var timeOfBirth = Date()
    var cityOfBirth = ""
    var gender = ""
    var timeUnknown = false
    
    // MARK: - UI State
    var isLoading = false
    var errorMessage: String?
    var showLocationSearch = false
    
    // MARK: - Computed Properties
    var isValid: Bool {
        !cityOfBirth.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: dateOfBirth)
    }
    
    var formattedTime: String {
        if timeUnknown { return "Unknown" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timeOfBirth)
    }
    
    /// Creates BirthData object from form values
    var birthData: BirthData {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        return BirthData(
            dob: dateFormatter.string(from: dateOfBirth),
            time: timeUnknown ? "12:00" : timeFormatter.string(from: timeOfBirth),
            latitude: 0, // Will be geocoded in future
            longitude: 0,
            cityOfBirth: cityOfBirth.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
    
    // MARK: - Actions
    
    /// Validate and save birth data
    func save() -> Bool {
        errorMessage = nil
        
        guard isValid else {
            errorMessage = "Please enter your city of birth"
            return false
        }
        
        // Save to persistent storage
        do {
            let encoded = try JSONEncoder().encode(birthData)
            UserDefaults.standard.set(encoded, forKey: "userBirthData")
            UserDefaults.standard.set(true, forKey: "hasBirthData")
            UserDefaults.standard.set(gender, forKey: "userGender")
            UserDefaults.standard.set(timeUnknown, forKey: "birthTimeUnknown")
            return true
        } catch {
            errorMessage = "Failed to save birth data"
            return false
        }
    }
    
    /// Load previously saved birth data
    func loadSaved() {
        if let data = UserDefaults.standard.data(forKey: "userBirthData"),
           let saved = try? JSONDecoder().decode(BirthData.self, from: data) {
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            if let date = dateFormatter.date(from: saved.dob) {
                dateOfBirth = date
            }
            
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            if let time = timeFormatter.date(from: saved.time) {
                timeOfBirth = time
            }
            
            cityOfBirth = saved.cityOfBirth ?? ""
            gender = UserDefaults.standard.string(forKey: "userGender") ?? ""
            timeUnknown = UserDefaults.standard.bool(forKey: "birthTimeUnknown")
        }
    }
}
