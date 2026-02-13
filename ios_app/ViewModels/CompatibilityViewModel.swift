import Foundation
import SwiftUI
import SwiftData

/// ViewModel for Compatibility/Match screen
@Observable
class CompatibilityViewModel {
    // MARK: - User ("You") Birth Data
    var boyName: String = ""
    var boyBirthDate: Date = Date()
    var boyBirthTime: Date = Date()
    var boyCity: String = ""
    var boyLatitude: Double = 0
    var boyLongitude: Double = 0
    var boyTimeUnknown: Bool = false
    var boyGender: String = ""
    var userDataLoaded: Bool = false
    
    // MARK: - Partner Data (via partners array)
    // All partner fields are now accessed via currentPartner computed property
    // Legacy accessors for backward-compatible View bindings:
    var girlName: String {
        get { currentPartner.name }
        set { 
            guard partners.indices.contains(activePartnerIndex) else { return }
            partners[activePartnerIndex].name = newValue 
        }
    }
    var girlBirthDate: Date {
        get { currentPartner.birthDate }
        set { 
            guard partners.indices.contains(activePartnerIndex) else { return }
            partners[activePartnerIndex].birthDate = newValue
            partners[activePartnerIndex].birthDateSet = true  // Mark as explicitly set
        }
    }
    var girlBirthTime: Date {
        get { currentPartner.birthTime }
        set { 
            guard partners.indices.contains(activePartnerIndex) else { return }
            partners[activePartnerIndex].birthTime = newValue
            partners[activePartnerIndex].birthTimeSet = true  // Mark as explicitly set
        }
    }
    var girlCity: String {
        get { currentPartner.city }
        set { 
            guard partners.indices.contains(activePartnerIndex) else { return }
            partners[activePartnerIndex].city = newValue 
        }
    }
    var girlLatitude: Double {
        get { currentPartner.latitude }
        set { 
            guard partners.indices.contains(activePartnerIndex) else { return }
            partners[activePartnerIndex].latitude = newValue 
        }
    }
    var girlLongitude: Double {
        get { currentPartner.longitude }
        set { 
            guard partners.indices.contains(activePartnerIndex) else { return }
            partners[activePartnerIndex].longitude = newValue 
        }
    }
    var partnerTimeUnknown: Bool {
        get { currentPartner.timeUnknown }
        set { 
            guard partners.indices.contains(activePartnerIndex) else { return }
            partners[activePartnerIndex].timeUnknown = newValue 
        }
    }
    var partnerGender: String {
        get { currentPartner.gender }
        set { 
            guard partners.indices.contains(activePartnerIndex) else { return }
            partners[activePartnerIndex].gender = newValue 
        }
    }
    
    // Analysis state
    var isAnalyzing = false
    var showResult = false
    var errorMessage: String?
    var result: CompatibilityResult?
    var sessionId: String? // For follow-up queries
    var historyLoadedToast = false // Shows brief "Loaded from history" indicator
    
    // Streaming progress state
    var currentStep: AnalysisStep = .calculatingCharts
    var streamingText: String = ""
    var showStreamingView: Bool = false
    
    // MARK: - Multi-Partner Support (Future-Ready)
    /// Array of partners for multi-partner comparison
    /// In v1 (multiPartnerComparison = false), this has exactly 1 element
    var partners: [PartnerData] = [PartnerData()]
    
    /// Index of active partner being edited (for v1 single-partner mode)
    var activePartnerIndex: Int = 0
    
    /// Stores all comparison results for multi-partner mode
    var comparisonResults: [ComparisonResult] = []
    
    /// Navigation state for multi-partner overview
    var showComparisonOverview: Bool = false
    
    /// Unique ID to group related matches in history (generated when analysis starts with >1 partner)
    var currentComparisonGroupId: String? = nil
    
    // MARK: - Current Partner (v1 Compatibility)
    /// Convenience accessor for the current partner being edited
    var currentPartner: PartnerData {
        get { partners.indices.contains(activePartnerIndex) ? partners[activePartnerIndex] : PartnerData() }
        set { 
            if partners.indices.contains(activePartnerIndex) {
                partners[activePartnerIndex] = newValue 
            }
        }
    }
    
    // MARK: - User Summary (for read-only "Your Details" card)
    var formattedUserSummary: String {
        var parts: [String] = []
        if !boyName.isEmpty { parts.append(boyName) }
        if !boyGender.isEmpty { parts.append(boyGender.capitalized) }
        parts.append(formattedBoyDob)
        if !boyTimeUnknown { parts.append(formattedBoyTime) }
        if !boyCity.isEmpty { parts.append(boyCity) }
        return parts.joined(separator: " · ")
    }
    
    // MARK: - Formatted Date Strings
    var formattedBoyDob: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: boyBirthDate)
    }
    
    var formattedGirlDob: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: girlBirthDate)
    }
    
    var formattedBoyTime: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: boyBirthTime)
    }
    
    var formattedGirlTime: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: girlBirthTime)
    }
    
    // MARK: - Dependencies
    private let compatibilityService: CompatibilityServiceProtocol
    
    // MARK: - Init
    init(compatibilityService: CompatibilityServiceProtocol = CompatibilityService()) {
        self.compatibilityService = compatibilityService
        loadUserDataFromProfile()
    }
    
    // MARK: - Load User Data
    /// Load user's birth data from profile (ProfileContextManager or UserDefaults)
    private func loadUserDataFromProfile() {
        // Check active profile first (for Switch Profile feature)
        if let profileBirthData = ProfileContextManager.shared.activeBirthData {
            print("[CompatibilityViewModel] Using birth data from active profile: \(ProfileContextManager.shared.activeProfileName)")
            
            boyName = ProfileContextManager.shared.activeProfileName
            
            // Parse date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            if let date = dateFormatter.date(from: profileBirthData.dob) {
                boyBirthDate = date
            }
            
            // Parse time
            let timeFormatter = DateFormatter()
            timeFormatter.locale = Locale(identifier: "en_US_POSIX")
            timeFormatter.dateFormat = "HH:mm"
            if let time = timeFormatter.date(from: profileBirthData.time) {
                boyBirthTime = time
            }
            
            // Set location
            boyCity = profileBirthData.cityOfBirth ?? ""
            boyLatitude = profileBirthData.latitude
            boyLongitude = profileBirthData.longitude
            boyTimeUnknown = profileBirthData.birthTimeUnknown ?? false
            boyGender = profileBirthData.gender ?? ""
            
            userDataLoaded = true
            return
        }
        
        // Fallback: Load from UserDefaults
        // Load name
        if let savedName = UserDefaults.standard.string(forKey: "userName"), !savedName.isEmpty {
            boyName = savedName
        }
        
        // Load birth data
        if let data = UserDefaults.standard.data(forKey: "userBirthData") {
            do {
                let birthData = try JSONDecoder().decode(BirthData.self, from: data)
                
                // Parse date
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                if let date = dateFormatter.date(from: birthData.dob) {
                    boyBirthDate = date
                }
                
                // Parse time (handle both 24-hour "HH:mm" and legacy 12-hour "h:mm a")
                let timeFormatter = DateFormatter()
                timeFormatter.locale = Locale(identifier: "en_US_POSIX")
                timeFormatter.dateFormat = "HH:mm"
                if let time = timeFormatter.date(from: birthData.time) {
                    boyBirthTime = time
                } else {
                    // Fallback: try 12-hour format for legacy data
                    let formatter12 = DateFormatter()
                    formatter12.locale = Locale(identifier: "en_US_POSIX")
                    formatter12.dateFormat = "h:mm a"
                    if let time = formatter12.date(from: birthData.time) {
                        boyBirthTime = time
                        print("[CompatibilityViewModel] Parsed legacy 12-hour time: \(birthData.time)")
                    }
                }
                
                // Set location
                boyCity = birthData.cityOfBirth ?? ""
                boyLatitude = birthData.latitude
                boyLongitude = birthData.longitude
                
                // Load time unknown flag (using user-scoped key)
                if let email = UserDefaults.standard.string(forKey: "userEmail") {
                    let timeUnknownKey = StorageKeys.userKey(for: StorageKeys.birthTimeUnknown, email: email)
                    boyTimeUnknown = UserDefaults.standard.bool(forKey: timeUnknownKey)
                    
                    // Load gender (using user-scoped key)
                    let genderKey = StorageKeys.userKey(for: StorageKeys.userGender, email: email)
                    boyGender = UserDefaults.standard.string(forKey: genderKey) ?? ""
                } else {
                    // Fallback for legacy data
                    boyTimeUnknown = UserDefaults.standard.bool(forKey: "birthTimeUnknown")
                    boyGender = UserDefaults.standard.string(forKey: "userGender") ?? ""
                }
                
                userDataLoaded = true
            } catch {
                print("Failed to decode user birth data: \(error)")
            }
        }
    }
    
    // MARK: - Validation
    var isFormValid: Bool {
        // Names, locations, and dates are now required
        !boyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !girlName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !boyCity.isEmpty &&
        !girlCity.isEmpty &&
        boyLatitude != 0 &&
        boyLongitude != 0 &&
        girlLatitude != 0 &&
        girlLongitude != 0 &&
        currentPartner.birthDateSet &&  // Date must be explicitly selected
        (currentPartner.birthTimeSet || partnerTimeUnknown)  // Time must be set OR marked as unknown
    }
    
    // Effective names with fallback
    var effectiveBoyName: String {
        boyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Not Provided" : boyName
    }
    
    var effectiveGirlName: String {
        girlName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Not Provided" : girlName
    }
    
    // MARK: - Partner Management (Multi-Partner Ready)
    /// Add a new empty partner to the list
    func addPartner() {
        guard AppTheme.Features.multiPartnerComparison else { return }
        partners.append(PartnerData())
        activePartnerIndex = partners.count - 1
        HapticManager.shared.play(.light)
    }
    
    /// Remove partner at specified index
    func removePartner(at index: Int) {
        guard partners.count > 1 else { return }  // Keep at least one
        guard partners.indices.contains(index) else { return }
        partners.remove(at: index)
        // Adjust active index if needed
        if activePartnerIndex >= partners.count {
            activePartnerIndex = partners.count - 1
        }
        HapticManager.shared.play(.medium)
    }
    
    /// Select a partner for editing
    func selectPartner(at index: Int) {
        guard partners.indices.contains(index) else { return }
        activePartnerIndex = index
        // Computed properties auto-sync; no manual sync needed
    }
    
    /// Load a saved partner into the current slot
    func loadSavedPartner(_ partner: PartnerProfile) {
        var partnerData = PartnerData()
        partnerData.name = partner.name
        partnerData.gender = partner.gender
        partnerData.city = partner.cityOfBirth ?? ""
        partnerData.latitude = partner.latitude ?? 0
        partnerData.longitude = partner.longitude ?? 0
        partnerData.placeId = ""  // Not stored in PartnerProfile
        
        // Parse date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        if let date = dateFormatter.date(from: partner.dateOfBirth) {
            partnerData.birthDate = date
            partnerData.birthDateSet = true
        }
        
        // Parse time
        if let timeStr = partner.timeOfBirth {
            let timeFormatter = DateFormatter()
            timeFormatter.locale = Locale(identifier: "en_US_POSIX")
            timeFormatter.dateFormat = "HH:mm"
            if let time = timeFormatter.date(from: timeStr) {
                partnerData.birthTime = time
                partnerData.birthTimeSet = true
            }
        }
        
        partnerData.timeUnknown = partner.birthTimeUnknown
        
        partners[activePartnerIndex] = partnerData
        HapticManager.shared.play(.light)
    }

    
    // MARK: - Save Partner
    // MARK: - Save Partners (Smart)
    @MainActor
    func saveAllPartners(context: ModelContext) {
        // Iterate through all partners
        for partner in partners {
            // Skip empty/invalid partners
            guard !partner.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  partner.birthDateSet else { continue }
            
            // Format dates
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dobStr = dateFormatter.string(from: partner.birthDate)
            
            let timeFormatter = DateFormatter()
            timeFormatter.locale = Locale(identifier: "en_US_POSIX")
            timeFormatter.dateFormat = "HH:mm"
            let timeStr = timeFormatter.string(from: partner.birthTime)
            
            let newPartner = PartnerProfile(
                name: partner.name,
                gender: partner.gender.isEmpty ? "female" : partner.gender,
                dateOfBirth: dobStr,
                timeOfBirth: timeStr,
                cityOfBirth: partner.city,
                latitude: partner.latitude,
                longitude: partner.longitude,
                birthTimeUnknown: partner.timeUnknown,
                consentGiven: true
            )
            
            // Save locally (Smart Check)
            PartnerProfileService.shared.savePartnerSmartly(newPartner, context: context)
            
            // Sync to API (fire and forget)
            Task {
                if let email = UserDefaults.standard.string(forKey: "userEmail"), !email.isEmpty {
                    do {
                        // API usually handles duplicates (returns existing or updates)
                        let created = try await PartnerProfileService.shared.createPartner(newPartner, email: email)
                        print("Synced partner: \(created.name)")
                    } catch {
                        print("Failed to sync partner: \(error)")
                    }
                }
            }
        }
    }

    // MARK: - Actions
    func analyzeMatch() async {
        guard isFormValid else {
            errorMessage = "Please fill in all required fields"
            return
        }
        
        // STEP 1: Check local cache/history BEFORE calling API (FREE if found)
        // This avoids re-triggering LLM for same match pair — usage count only for NEW matches
        let dobFmt = DateFormatter()
        dobFmt.dateFormat = "dd/MM/yyyy"
        let timeFmt = DateFormatter()
        timeFmt.locale = Locale(identifier: "en_US_POSIX")
        timeFmt.dateFormat = "HH:mm:ss"
        
        if let existingMatch = CompatibilityHistoryService.shared.findExistingMatch(
            boyDob: dobFmt.string(from: boyBirthDate),
            boyTime: timeFmt.string(from: boyBirthTime),
            girlDob: dobFmt.string(from: girlBirthDate),
            girlTime: timeFmt.string(from: girlBirthTime)
        ) {
            print("[CompatibilityViewModel] Found existing match in local history — loading FREE (no API call)")
            await MainActor.run {
                loadFromHistory(existingMatch)
                historyLoadedToast = true
            }
            return
        }
        
        // STEP 2: Not found in cache - proceed with quota check and API call
        let currentEmail = UserDefaults.standard.string(forKey: "userEmail") ?? "guest"
        
        await MainActor.run {
            isAnalyzing = true
            showStreamingView = true
            currentStep = .calculatingCharts
            streamingText = ""
            errorMessage = nil
        }
        
        // Verify quota with backend
        do {
            let accessResponse = try await QuotaManager.shared.canAccessFeature(.compatibility, email: currentEmail)
            if !accessResponse.canAccess {
                await MainActor.run {
                    isAnalyzing = false
                    showStreamingView = false
                    // Professional Quota UI - Daily=banner, Overall/Feature=sheet (handled by View)
                    if accessResponse.reason == "daily_limit_reached" {
                        // DAILY LIMIT: Show error message (banner), no sheet
                        if let resetAtStr = accessResponse.resetAt,
                           let date = ISO8601DateFormatter().date(from: resetAtStr) {
                            let timeFormatter = DateFormatter()
                            timeFormatter.timeStyle = .short
                            let timeStr = timeFormatter.string(from: date)
                            errorMessage = "Daily limit reached. Resets at \(timeStr)."
                        } else {
                            errorMessage = "Daily limit reached. Resets tomorrow."
                        }
                    } else if accessResponse.reason == "overall_limit_reached" {
                        // OVERALL LIMIT: Set flag for View to show sheet
                        if currentEmail.contains("guest") || currentEmail.contains("@gen.com") {
                            errorMessage = "FREE_LIMIT_GUEST"  // Special marker for View to show sheet
                        } else {
                            errorMessage = "FREE_LIMIT_REGISTERED"  // Special marker for View to show sheet
                        }
                    } else {
                        // FEATURE NOT AVAILABLE: Set flag for View to show sheet
                        errorMessage = "FEATURE_UPGRADE_REQUIRED"  // Special marker for View to show sheet
                    }
                }
                return
            }
        } catch {
            print("Quota check failed: \(error)")
        }
        
        // Quota is now recorded server-side by /compatibility/analyze endpoint

        await MainActor.run {
            isAnalyzing = true
            showStreamingView = true
            currentStep = .calculatingCharts
            streamingText = ""
            errorMessage = nil
        }
        
        do {
            // Build API request
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")  // Ensures Gregorian + ASCII
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let timeFormatter = DateFormatter()
            timeFormatter.locale = Locale(identifier: "en_US_POSIX")  // Ensures 24-hour format
            timeFormatter.dateFormat = "HH:mm:ss"
            
            // Round coordinates to 6 decimal places (backend validation requirement)
            let roundedBoyLat = (boyLatitude * 1_000_000).rounded() / 1_000_000
            let roundedBoyLon = (boyLongitude * 1_000_000).rounded() / 1_000_000
            let roundedGirlLat = (girlLatitude * 1_000_000).rounded() / 1_000_000
            let roundedGirlLon = (girlLongitude * 1_000_000).rounded() / 1_000_000
            
            let request = CompatibilityRequest(
                boy: BirthDetails(
                    dob: dateFormatter.string(from: boyBirthDate),
                    time: timeFormatter.string(from: boyBirthTime),
                    lat: roundedBoyLat,
                    lon: roundedBoyLon,
                    name: boyName,
                    place: boyCity
                ),
                girl: BirthDetails(
                    dob: dateFormatter.string(from: girlBirthDate),
                    time: timeFormatter.string(from: girlBirthTime),
                    lat: roundedGirlLat,
                    lon: roundedGirlLon,
                    name: girlName,
                    place: girlCity
                ),
                sessionId: "sess_\(Int(Date().timeIntervalSince1970 * 1000))",
                userEmail: UserDefaults.standard.string(forKey: "userEmail"),  // Pass real email for history storage
                profileId: ProfileContextManager.shared.activeProfileId,  // Profile-scoped threads
                comparisonGroupId: currentComparisonGroupId,  // Multi-partner grouping
                partnerIndex: partners.count > 1 ? activePartnerIndex : nil  // Partner order in group
            )
            
            // DEBUG: Log userEmail being sent
            let debugEmail = UserDefaults.standard.string(forKey: "userEmail")
            print("[CompatibilityViewModel] DEBUG: UserDefaults 'userEmail' = '\(debugEmail ?? "NIL")'")
            print("[CompatibilityViewModel] DEBUG: request.userEmail = '\(request.userEmail ?? "NIL")'")
            print("[CompatibilityViewModel] GENERATED session_id in request: \(request.sessionId ?? "NIL")")
            
            // Call streaming API with progress callback
            let response: CompatibilityResponse
            if let service = compatibilityService as? CompatibilityService {
                response = try await service.analyzeWithProgress(request: request) { [weak self] step, _ in
                    self?.updateStep(step)
                }
            } else {
                response = try await compatibilityService.analyzeStream(request: request)
            }
            
            // Parse ashtakoot data from response
            let result = parseApiResponse(response)
            
            await MainActor.run {
                self.currentStep = .complete
                self.result = result
                isAnalyzing = false
                showStreamingView = false
                showResult = true
                
                // Save to history with multi-partner grouping info
                let groupId = partners.count > 1 ? currentComparisonGroupId : nil
                let index = partners.count > 1 ? activePartnerIndex : nil
                self.saveToHistory(result: result, groupId: groupId, partnerIndex: index)
            }
        } catch {
            await MainActor.run {
                errorMessage = "Analysis failed: \(error.localizedDescription)"
                isAnalyzing = false
                showStreamingView = false
            }
        }
    }
    
    // MARK: - Multi-Partner Analysis
    /// Analyzes ALL partners sequentially and populates comparisonResults
    func analyzeAllPartners() async {
        guard partners.count >= 1 else { return }
        
        // Generate unique group ID for this comparison session
        currentComparisonGroupId = UUID().uuidString
        
        // Clear previous results
        await MainActor.run {
            comparisonResults = []
            isAnalyzing = true
            showStreamingView = true
            currentStep = .calculatingCharts
            streamingText = ""
            errorMessage = nil
        }
        
        let currentEmail = UserDefaults.standard.string(forKey: "userEmail") ?? "guest"
        
        // Check quota once for all partners
        do {
            let accessResponse = try await QuotaManager.shared.canAccessFeature(.compatibility, email: currentEmail)
            if !accessResponse.canAccess {
                await MainActor.run {
                    isAnalyzing = false
                    showStreamingView = false
                    errorMessage = accessResponse.reason == "daily_limit_reached" 
                        ? "Daily limit reached" 
                        : "FREE_LIMIT_REGISTERED"
                }
                return
            }
        } catch {
            print("Quota check failed: \(error)")
        }
        
        // Analyze each partner sequentially
        for (index, partner) in partners.enumerated() {
            // Update UI to show current partner being analyzed
            await MainActor.run {
                activePartnerIndex = index
                streamingText = "Analyzing \(partner.name.isEmpty ? "Partner \(index + 1)" : partner.name)..."
                currentStep = .calculatingCharts
            }
            
            // Skip incomplete partners
            guard partner.isComplete else {
                print("[Multi-Partner] Skipping incomplete partner at index \(index)")
                continue
            }
            
            // Check if this partner match already exists in cache (FREE if found)
            let partnerDobFmt = DateFormatter()
            partnerDobFmt.dateFormat = "dd/MM/yyyy"
            let partnerTimeFmt = DateFormatter()
            partnerTimeFmt.locale = Locale(identifier: "en_US_POSIX")
            partnerTimeFmt.dateFormat = "HH:mm:ss"
            
            if let existingMatch = CompatibilityHistoryService.shared.findExistingMatch(
                boyDob: partnerDobFmt.string(from: boyBirthDate),
                boyTime: partnerTimeFmt.string(from: boyBirthTime),
                girlDob: partnerDobFmt.string(from: partner.birthDate),
                girlTime: partnerTimeFmt.string(from: partner.birthTime)
            ),
            let cachedCompatibilityResult = existingMatch.result {
                print("[Multi-Partner] Found existing match for \(partner.name) in cache - loading FREE")
                await MainActor.run {
                    // Add to comparison results from cache (no LLM call)
                    let cachedResult = ComparisonResult(
                        partner: partner,
                        result: cachedCompatibilityResult
                    )
                    comparisonResults.append(cachedResult)
                }
                continue  // Skip API call for this partner
            }
            
            do {
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let timeFormatter = DateFormatter()
                timeFormatter.locale = Locale(identifier: "en_US_POSIX")
                timeFormatter.dateFormat = "HH:mm:ss"
                
                // Round coordinates
                let roundedBoyLat = (boyLatitude * 1_000_000).rounded() / 1_000_000
                let roundedBoyLon = (boyLongitude * 1_000_000).rounded() / 1_000_000
                let roundedPartnerLat = (partner.latitude * 1_000_000).rounded() / 1_000_000
                let roundedPartnerLon = (partner.longitude * 1_000_000).rounded() / 1_000_000
                
                let request = CompatibilityRequest(
                    boy: BirthDetails(
                        dob: dateFormatter.string(from: boyBirthDate),
                        time: timeFormatter.string(from: boyBirthTime),
                        lat: roundedBoyLat,
                        lon: roundedBoyLon,
                        name: boyName,
                        place: boyCity
                    ),
                    girl: BirthDetails(
                        dob: dateFormatter.string(from: partner.birthDate),
                        time: timeFormatter.string(from: partner.birthTime),
                        lat: roundedPartnerLat,
                        lon: roundedPartnerLon,
                        name: partner.name,
                        place: partner.city
                    ),
                    sessionId: "sess_\(Int(Date().timeIntervalSince1970 * 1000))",
                    userEmail: currentEmail,
                    profileId: ProfileContextManager.shared.activeProfileId,  // Profile-scoped threads
                    comparisonGroupId: currentComparisonGroupId,
                    partnerIndex: index
                )
                
                // Call API
                let response: CompatibilityResponse
                if let service = compatibilityService as? CompatibilityService {
                    response = try await service.analyzeWithProgress(request: request) { [weak self] step, _ in
                        self?.updateStep(step)
                    }
                } else {
                    response = try await compatibilityService.analyzeStream(request: request)
                }
                
                let result = parseApiResponse(response)
                
                // Add to comparison results
                await MainActor.run {
                    let compResult = ComparisonResult(partner: partner, result: result)
                    comparisonResults.append(compResult)
                    saveToHistory(result: result, groupId: currentComparisonGroupId, partnerIndex: index)
                }
                
            } catch {
                print("[Multi-Partner] Analysis failed for partner \(index): \(error)")
            }
        }
        
        // All done - show overview
        await MainActor.run {
            currentStep = .complete
            isAnalyzing = false
            showStreamingView = false
            
            if comparisonResults.count > 1 {
                // Multi-partner: show overview
                showComparisonOverview = true
            } else if let first = comparisonResults.first {
                // Single partner fallback: show result directly
                result = first.result
                showResult = true
            }
        }
    }
    // MARK: - History
    private func saveToHistory(result: CompatibilityResult, groupId: String? = nil, partnerIndex: Int? = nil) {
        guard let sid = result.sessionId else { return }
        // Use compat_ prefix to match backend thread_id format
        let storageSessionId = sid.hasPrefix("compat_") ? sid : "compat_\(sid)"
        
        // Format times for storage (HH:mm:ss format for backend compatibility)
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.dateFormat = "HH:mm:ss"
        let boyTimeStr = timeFormatter.string(from: boyBirthTime)
        let girlTimeStr = timeFormatter.string(from: girlBirthTime)
        
        let item = CompatibilityHistoryItem(
            sessionId: storageSessionId,
            timestamp: Date(),
            boyName: boyName,
            boyDob: formattedBoyDob,
            boyTime: boyTimeStr,
            boyCity: boyCity,
            girlName: girlName,
            girlDob: formattedGirlDob,
            girlTime: girlTimeStr,
            girlCity: girlCity,
            totalScore: result.totalScore,
            maxScore: result.maxScore,
            result: result,
            chatMessages: [], // Chat starts empty
            comparisonGroupId: groupId,
            partnerIndex: partnerIndex
        )
        
        CompatibilityHistoryService.shared.save(item)
    }
    
    /// Load state from a history item
    func loadFromHistory(_ item: CompatibilityHistoryItem) {
        // Restore properties
        boyName = item.boyName
        girlName = item.girlName
        boyCity = item.boyCity
        girlCity = item.girlCity
        
        // Restore dates (parsing strings back to dates if needed, or better to store dates in HistoryItem?)
        // The HistoryItem has formatted strings for display, but also SHOULD store raw dates if we want to edit.
        // For now, we update the display state. The ViewModel stores Date objects.
        // Ideally HistoryItem should store Date objects or TimeIntervals.
        // Looking at CompatibilityHistoryItem.swift, it has `timestamp` but inputs are strings?
        // Ah, in current HistoryItem I put `boyDob: String` (formatted).
        // If we want to fully restore the *form* state (dates), we might need to parse or store raw dates.
        // BUT, for displaying the result, we largely rely on `result` object.
        // Let's rely on `item.result` for the analysis data.
        
        // Restore result
        if let savedResult = item.result {
            self.result = savedResult
            self.showResult = true
        }
    }
    
    /// Load state from a history group (multi-partner comparison)
    /// Reconstructs ComparisonResult array from the group's items and shows ComparisonOverviewView
    func loadFromHistoryGroup(_ group: ComparisonGroup) {
        // Set the user (boy) name from the group
        boyName = group.userName
        
        // Convert each history item in the group to a ComparisonResult
        var results: [ComparisonResult] = []
        for item in group.items {
            guard let savedResult = item.result else { continue }
            
            // Reconstruct PartnerData from history item
            let partner = PartnerData(
                name: item.girlName,
                city: item.girlCity
            )
            
            let compResult = ComparisonResult(
                partner: partner,
                result: savedResult
            )
            results.append(compResult)
        }
        
        // Populate comparison results and show overview
        if results.count > 1 {
            comparisonResults = results
            showComparisonOverview = true
            showResult = false
        } else if let single = results.first {
            // Fallback for single item in group (shouldn't happen, but safe)
            result = single.result
            girlName = single.partner.name
            showResult = true
        }
    }
    
    /// Map SSE step name to AnalysisStep enum
    private func updateStep(_ stepName: String) {
        // Backend sends: calculate_charts, ashtakoot, mangal_compat, yoga_kalsarpa, formatting, llm
        let stepMapping: [String: AnalysisStep] = [
            "calculate_charts": .calculatingCharts,
            "ashtakoot": .ashtakootMatching,
            "mangal_compat": .mangalDosha,
            "yoga_kalsarpa": .collectingYogas,
            "formatting": .collectingYogas,
            "llm": .generatingAnalysis
        ]
        
        if let step = stepMapping[stepName] {
            currentStep = step
        }
        print("[ViewModel] Step update: \(stepName) -> \(currentStep)")
    }
    
    /// Parse API response to CompatibilityResult with analysisData
    private func parseApiResponse(_ response: CompatibilityResponse) -> CompatibilityResult {
        var kutas: [KutaDetail] = []
        var totalScore: Int = 0
        let maxScore = 36
        
        // Extract Kuta details from ashtakoot matching if available
        if let joint = response.analysisData?.joint,
           let ashtakoot = joint.ashtakootMatching {
            
            // Parse kuta values from guna_scores nested inside ashtakoot_matching
            // API structure: ashtakoot_matching.guna_scores.varna.score
            let kutaNames = [
                ("varna", "Varna", 1),
                ("vashya", "Vashya", 2),
                ("tara", "Tara", 3),
                ("yoni", "Yoni", 4),
                ("maitri", "Maitri", 5),
                ("gana", "Gana", 6),
                ("bhakoot", "Bhakoot", 7),
                ("nadi", "Nadi", 8)
            ]
            
            // First try to get guna_scores nested object
            if let gunaScores = ashtakoot["guna_scores"]?.value as? [String: Any] {
                for (key, name, maxPoints) in kutaNames {
                    if let kutaData = gunaScores[key] as? [String: Any] {
                        let scoreVal: Int
                        if let s = kutaData["score"] as? Int {
                            scoreVal = s
                        } else if let s = kutaData["score"] as? Double {
                            scoreVal = Int(s)
                        } else {
                            scoreVal = 0
                        }
                        
                        let desc = kutaData["description"] as? String ?? ""
                        kutas.append(KutaDetail(name: name, maxPoints: maxPoints, points: scoreVal, description: desc))
                        totalScore += scoreVal
                    }
                }
            } else {
                // Fallback: try direct access (old structure)
                for (key, name, maxPoints) in kutaNames {
                    if let kutaData = ashtakoot[key]?.value as? [String: Any],
                       let score = kutaData["score"] as? Double {
                        let points = Int(score)
                        let desc = kutaData["description"] as? String ?? ""
                        kutas.append(KutaDetail(name: name, maxPoints: maxPoints, points: points, description: desc))
                        totalScore += points
                    }
                }
            }
            
            // Extract total score if available
            if let total = ashtakoot["total_score"]?.value as? Double {
                totalScore = Int(total)
            } else if let total = ashtakoot["total_score"]?.value as? Int {
                totalScore = total
            }
        }
        
        // If no kutas parsed, generate mock
        if kutas.isEmpty {
            kutas = [
                KutaDetail(name: "Varna", maxPoints: 1, points: 1, description: "Work compatibility"),
                KutaDetail(name: "Vashya", maxPoints: 2, points: 1, description: "Dominance compatibility"),
                KutaDetail(name: "Tara", maxPoints: 3, points: 2, description: "Destiny compatibility"),
                KutaDetail(name: "Yoni", maxPoints: 4, points: 2, description: "Intimacy compatibility"),
                KutaDetail(name: "Maitri", maxPoints: 5, points: 3, description: "Friendship compatibility"),
                KutaDetail(name: "Gana", maxPoints: 6, points: 3, description: "Temperament compatibility"),
                KutaDetail(name: "Bhakoot", maxPoints: 7, points: 4, description: "Emotional compatibility"),
                KutaDetail(name: "Nadi", maxPoints: 8, points: 4, description: "Health compatibility")
            ]
            totalScore = 20
        }
        
        // Generate summary based on score
        let summary: String
        if totalScore >= 28 {
            summary = "This is an excellent match with strong compatibility across all major areas."
        } else if totalScore >= 21 {
            summary = "A good match with solid foundations. Some areas may require conscious effort."
        } else {
            summary = "This match has some challenging aspects that require awareness and effort."
        }
        let rec = totalScore >= 18 ? "Favorable for marriage" : "Additional remedies may be helpful"
        
        print("[CompatibilityViewModel] STORING session_id in result: \(response.sessionId ?? "NIL")")
        
        return CompatibilityResult(
            totalScore: totalScore,
            maxScore: maxScore,
            kutas: kutas,
            summary: response.llmAnalysis ?? "\(totalScore)/36",
            recommendation: rec,
            analysisData: response.analysisData,
            sessionId: response.sessionId
        )
    }
    
    func reset() {
        // Only reset partner data, keep user data from profile
        girlName = ""
        girlBirthDate = Date()
        girlBirthTime = Date()
        girlCity = ""
        girlLatitude = 0
        girlLongitude = 0
        partnerTimeUnknown = false
        result = nil
        showResult = false
        errorMessage = nil
        
        // Reset multi-partner state
        partners = [PartnerData()]
        activePartnerIndex = 0
        comparisonResults = []
        showComparisonOverview = false
        currentComparisonGroupId = nil
        
        // Reload user data from profile
        loadUserDataFromProfile()
    }
    
    /// Public method to reload user data from active profile
    /// Called when profile context changes (Switch Profile feature)
    func reloadUserData() {
        loadUserDataFromProfile()
    }
    
    // MARK: - Mock Result
    private func generateMockResult() -> CompatibilityResult {
        let totalScore = Int.random(in: 18...32)
        let maxScore = 36
        
        let kutas = [
            KutaDetail(name: "Varna", maxPoints: 1, points: Int.random(in: 0...1), description: "Work & Ego match"),
            KutaDetail(name: "Vashya", maxPoints: 2, points: Int.random(in: 0...2), description: "Mutual attraction"),
            KutaDetail(name: "Tara", maxPoints: 3, points: Int.random(in: 0...3), description: "Destiny & Luck"),
            KutaDetail(name: "Yoni", maxPoints: 4, points: Int.random(in: 0...4), description: "Physical compatibility"),
            KutaDetail(name: "Graha Maitri", maxPoints: 5, points: Int.random(in: 0...5), description: "Mental friendship"),
            KutaDetail(name: "Gana", maxPoints: 6, points: Int.random(in: 0...6), description: "Temperament match"),
            KutaDetail(name: "Bhakoot", maxPoints: 7, points: Int.random(in: 0...7), description: "Love & Happiness"),
            KutaDetail(name: "Nadi", maxPoints: 8, points: Int.random(in: 0...8), description: "Health & Genes")
        ]
        
        let summary: String
        if totalScore >= 28 {
            summary = "This is an excellent match with strong compatibility across all major areas. The couple shares deep emotional understanding and complementary energies."
        } else if totalScore >= 21 {
            summary = "A good match with solid foundations. Some areas may require conscious effort, but overall compatibility is favorable for a harmonious relationship."
        } else {
            summary = "This match has some challenging aspects that require awareness and effort. With understanding and patience, the relationship can still flourish."
        }
        
        return CompatibilityResult(
            totalScore: totalScore,
            maxScore: maxScore,
            kutas: kutas,
            summary: summary,
            recommendation: totalScore >= 18 ? "Favorable for marriage" : "Additional remedies may be helpful"
        )
    }
}

// MARK: - Models
struct CompatibilityResult: Identifiable, Codable {
    let id = UUID()
    let totalScore: Int
    let maxScore: Int
    let kutas: [KutaDetail]
    let summary: String
    let recommendation: String
    let analysisData: AnalysisData?
    let sessionId: String?
    
    var percentage: Double {
        guard maxScore > 0 else { return 0 }
        return Double(totalScore) / Double(maxScore)
    }
    
    init(
        totalScore: Int,
        maxScore: Int,
        kutas: [KutaDetail],
        summary: String,
        recommendation: String,
        analysisData: AnalysisData? = nil,
        sessionId: String? = nil
    ) {
        self.totalScore = totalScore
        self.maxScore = maxScore
        self.kutas = kutas
        self.summary = summary
        self.recommendation = recommendation
        self.analysisData = analysisData
        self.sessionId = sessionId
    }
}

struct KutaDetail: Identifiable, Codable {
    let id = UUID()
    let name: String
    let maxPoints: Int
    let points: Int
    let description: String
    
    // Custom CodingKeys to handle optional description for backwards compatibility
    enum CodingKeys: String, CodingKey {
        case name, maxPoints, points, description
    }
    
    init(name: String, maxPoints: Int, points: Int, description: String = "") {
        self.name = name
        self.maxPoints = maxPoints
        self.points = points
        self.description = description
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        maxPoints = try container.decode(Int.self, forKey: .maxPoints)
        points = try container.decode(Int.self, forKey: .points)
        // Make description optional for backwards compatibility
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
    }
    
    var percentage: Double {
        guard maxPoints > 0 else { return 0 }
        return Double(points) / Double(maxPoints)
    }
}
