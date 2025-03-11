import SwiftUI
import EventKit

// Custom color scheme
struct AppColors {
    static let primary = Color(red: 0.2, green: 0.5, blue: 0.8)
    static let secondary = Color(red: 0.9, green: 0.4, blue: 0.4)
    static let background = Color(red: 0.95, green: 0.97, blue: 1.0)
    static let cardBackground = Color.white
    static let text = Color(red: 0.2, green: 0.2, blue: 0.3)
    static let eventIndicator = Color(red: 0.9, green: 0.4, blue: 0.4)
}

// Custom text field style
struct CustomTextField: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(AppColors.cardBackground)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// Custom button style
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(configuration.isPressed ? AppColors.primary.opacity(0.8) : AppColors.primary)
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(), value: configuration.isPressed)
    }
}

// Custom calendar view with event indicators
struct CustomCalendarView: View {
    @Binding var selectedDate: Date
    let eventDates: [Date]
    let onDateChanged: () -> Void
    
    var body: some View {
        VStack {
            DatePicker("", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
                .background(AppColors.cardBackground)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                .onChange(of: selectedDate) { _ in
                    onDateChanged()
                }
            
            // Event indicators legend
            HStack {
                Circle()
                    .fill(AppColors.eventIndicator)
                    .frame(width: 8, height: 8)
                
                Text("Events on this date")
                    .font(.caption)
                    .foregroundColor(AppColors.text.opacity(0.7))
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
}

// Event Card View
struct EventCardView: View {
    let event: EKEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(Color(event.calendar.cgColor))
                    .frame(width: 12, height: 12)
                
                Text(event.title)
                    .font(.headline)
                    .foregroundColor(AppColors.text)
                
                Spacer()
                
                Text(formatTime(event.startDate))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(formatDate(event.startDate))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
    
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// Custom UIDatePicker wrapper that can show event indicators
struct EventIndicatorDatePicker: UIViewRepresentable {
    @Binding var date: Date
    var eventDates: [Date]
    var onChange: (Date) -> Void
    
    func makeUIView(context: Context) -> UIDatePicker {
        let picker = UIDatePicker()
        picker.datePickerMode = .dateAndTime
        picker.preferredDatePickerStyle = .automatic
        picker.addTarget(context.coordinator, action: #selector(Coordinator.dateChanged(_:)), for: .valueChanged)
        return picker
    }
    
    func updateUIView(_ uiView: UIDatePicker, context: Context) {
        uiView.date = date
        
        // We need to use this undocumented method to show event indicators
        // Note: This is a private API, so it might not work in future iOS versions
        if let calendarView = findCalendarView(in: uiView) {
            highlightDates(in: calendarView)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(date: $date, onChange: onChange)
    }
    
    private func findCalendarView(in view: UIView) -> UIView? {
        // Find the calendar subview
        for subview in view.subviews {
            if String(describing: type(of: subview)).contains("Calendar") {
                return subview
            }
            if let found = findCalendarView(in: subview) {
                return found
            }
        }
        return nil
    }
    
    private func highlightDates(in calendarView: UIView) {
        // This is a placeholder for the actual implementation
        // The real implementation would use private APIs to add indicators
        // Since we can't rely on private APIs, we'll use our custom solution instead
    }
    
    class Coordinator: NSObject {
        @Binding var date: Date
        var onChange: (Date) -> Void
        
        init(date: Binding<Date>, onChange: @escaping (Date) -> Void) {
            self._date = date
            self.onChange = onChange
        }
        
        @objc func dateChanged(_ sender: UIDatePicker) {
            date = sender.date
            onChange(sender.date)
        }
    }
}

struct EventView: View {
    @State private var eventTitle = ""
    @State private var eventDate = Date()
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var calendarAccessStatus: EKAuthorizationStatus = .notDetermined
    @State private var upcomingEvents: [EKEvent] = []
    @State private var allEventDates: [Date] = []
    @State private var isLoading = false
    @State private var monthEvents: [String: Int] = [:]
    
    // Event store to interact with the Calendar
    let eventStore = EKEventStore()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Calendar date selector
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Select Date")
                                .font(.headline)
                                .foregroundColor(AppColors.text)
                                .padding(.horizontal)
                            
                            VStack {
                                DatePicker("", selection: $eventDate, displayedComponents: [.date, .hourAndMinute])
                                    .datePickerStyle(GraphicalDatePickerStyle())
                                    .padding()
                                    .background(AppColors.cardBackground)
                                    .cornerRadius(16)
                                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                                    .onChange(of: eventDate) { _ in
                                        fetchEvents()
                                    }
                                
                                // Event date indicators
                                HStack {
                                    if !monthEvents.isEmpty {
                                        HStack(spacing: 3) {
                                            Image(systemName: "calendar.badge.exclamationmark")
                                                .foregroundColor(AppColors.secondary)
                                            
                                            Text("Days with events are highlighted")
                                                .font(.caption)
                                                .foregroundColor(AppColors.text.opacity(0.7))
                                        }
                                    } else {
                                        HStack(spacing: 3) {
                                            Image(systemName: "calendar")
                                                .foregroundColor(.gray)
                                            
                                            Text("No events found this month")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 8)
                            }
                        }
                        
                        // Event Month Summary
                        if !monthEvents.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Month at a Glance")
                                    .font(.headline)
                                    .foregroundColor(AppColors.text)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(sortedMonthDates(), id: \.self) { dateString in
                                            if let count = monthEvents[dateString] {
                                                VStack {
                                                    Text(shortDateFormat(from: dateString))
                                                        .font(.caption)
                                                        .bold()
                                                    
                                                    ZStack {
                                                        Circle()
                                                            .fill(isSelectedDate(dateString) ? AppColors.primary : AppColors.secondary.opacity(0.2))
                                                            .frame(width: 36, height: 36)
                                                        
                                                        Text("\(count)")
                                                            .font(.caption)
                                                            .bold()
                                                            .foregroundColor(isSelectedDate(dateString) ? .white : AppColors.text)
                                                    }
                                                    
                                                    Text(dayOfWeek(from: dateString))
                                                        .font(.caption2)
                                                        .foregroundColor(.gray)
                                                }
                                                .padding(.vertical, 4)
                                                .padding(.horizontal, 8)
                                                .background(isSelectedDate(dateString) ? AppColors.primary.opacity(0.1) : Color.clear)
                                                .cornerRadius(8)
                                                .onTapGesture {
                                                    if let date = dateFromString(dateString) {
                                                        eventDate = date
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 4)
                                }
                            }
                            .padding()
                            .background(AppColors.cardBackground)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        }
                        
                        // Event details card
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Event Details")
                                .font(.headline)
                                .foregroundColor(AppColors.text)
                            
                            TextField("Event Title", text: $eventTitle)
                                .modifier(CustomTextField())
                            
                            Button(action: {
                                checkCalendarAuthorizationStatus()
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add to Calendar")
                                        .fontWeight(.semibold)
                                }
                            }
                            .buttonStyle(PrimaryButtonStyle())
                        }
                        .padding()
                        .background(AppColors.cardBackground)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        
                        // Upcoming events section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Events on \(formatShortDate(eventDate))")
                                    .font(.headline)
                                    .foregroundColor(AppColors.text)
                                
                                Spacer()
                                
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                }
                            }
                            
                            if upcomingEvents.isEmpty {
                                HStack {
                                    Spacer()
                                    VStack(spacing: 12) {
                                        Image(systemName: "calendar.badge.clock")
                                            .font(.largeTitle)
                                            .foregroundColor(.secondary)
                                        Text("No events found")
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 20)
                                    Spacer()
                                }
                            } else {
                                ForEach(upcomingEvents, id: \.eventIdentifier) { event in
                                    EventCardView(event: event)
                                }
                            }
                        }
                        .padding()
                        .background(AppColors.cardBackground)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                    .padding()
                }
            }
            .navigationTitle("Calendar Events")
            .alert(isPresented: $showAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .onAppear {
                calendarAccessStatus = EKEventStore.authorizationStatus(for: .event)
                if calendarAccessStatus == .authorized {
                    fetchEvents()
                    fetchMonthEvents()
                }
            }
        }
    }
    
    // Helper function to format date string for month view
    func shortDateFormat(from dateString: String) -> String {
        let components = dateString.split(separator: "-")
        if components.count >= 2 {
            return String(components[2])
        }
        return ""
    }
    
    // Helper function to get day of week
    func dayOfWeek(from dateString: String) -> String {
        guard let date = dateFromString(dateString) else { return "" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    // Convert string to date
    func dateFromString(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date()) == dateString ? Date() : formatter.date(from: dateString)
    }
    
    // Check if date string is the selected date
    func isSelectedDate(_ dateString: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: eventDate) == dateString
    }
    
    // Sort month dates
    func sortedMonthDates() -> [String] {
        return monthEvents.keys.sorted()
    }
    
    // Format date for display
    func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    // Fetch events for the month
    func fetchMonthEvents() {
        guard EKEventStore.authorizationStatus(for: .event) == .authorized else { return }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: eventDate)
        
        guard let startDate = calendar.date(from: components),
              let endDate = calendar.date(byAdding: .month, value: 1, to: startDate) else {
            return
        }
        
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        
        DispatchQueue.global(qos: .userInitiated).async {
            let events = self.eventStore.events(matching: predicate)
            
            // Group events by date
            var eventsByDate: [String: Int] = [:]
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            
            for event in events {
                let dateString = formatter.string(from: event.startDate)
                if let count = eventsByDate[dateString] {
                    eventsByDate[dateString] = count + 1
                } else {
                    eventsByDate[dateString] = 1
                }
            }
            
            DispatchQueue.main.async {
                self.monthEvents = eventsByDate
            }
        }
    }
    
    // Fetch events for the selected date
    func fetchEvents() {
        isLoading = true
        
        // If not authorized, don't try to fetch
        if EKEventStore.authorizationStatus(for: .event) != .authorized {
            isLoading = false
            return
        }
        
        // Create start and end date components for the selected date
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: eventDate)
        let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!
        
        // Create the predicate to fetch events
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        
        // Fetch events
        DispatchQueue.global(qos: .userInitiated).async {
            let events = self.eventStore.events(matching: predicate)
            DispatchQueue.main.async {
                self.upcomingEvents = events.sorted { $0.startDate < $1.startDate }
                self.isLoading = false
            }
        }
    }
    
    // Check and request calendar authorization if needed
    func checkCalendarAuthorizationStatus() {
        let status = EKEventStore.authorizationStatus(for: .event)
        
        switch status {
        case .authorized:
            addEventToCalendar()
        case .denied, .restricted:
            // User has denied access to calendar
            alertTitle = "Calendar Access Denied"
            alertMessage = "Please go to Settings and enable calendar access for this app"
            showAlert = true
        case .notDetermined:
            // Request permission
            requestCalendarAccess()
        @unknown default:
            alertTitle = "Error"
            alertMessage = "Unknown authorization status"
            showAlert = true
        }
    }
    
    // Request calendar access
    func requestCalendarAccess() {
        if #available(iOS 17.0, *) {
            // iOS 17 and newer
            eventStore.requestFullAccessToEvents { granted, error in
                DispatchQueue.main.async {
                    if granted {
                        self.addEventToCalendar()
                        self.fetchEvents()
                        self.fetchMonthEvents()
                    } else {
                        self.alertTitle = "Access Denied"
                        self.alertMessage = "Calendar access was denied"
                        self.showAlert = true
                    }
                }
            }
        } else {
            // iOS 16 and older
            eventStore.requestAccess(to: .event) { granted, error in
                DispatchQueue.main.async {
                    if granted {
                        self.addEventToCalendar()
                        self.fetchEvents()
                        self.fetchMonthEvents()
                    } else {
                        self.alertTitle = "Access Denied"
                        self.alertMessage = "Calendar access was denied"
                        self.showAlert = true
                    }
                }
            }
        }
    }
    
    func addEventToCalendar() {
        // Check if event title is empty
        if eventTitle.isEmpty {
            alertTitle = "Error"
            alertMessage = "Please enter an event title"
            showAlert = true
            return
        }
        
        // Create event
        let event = EKEvent(eventStore: self.eventStore)
        event.title = self.eventTitle
        event.startDate = self.eventDate
        event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: self.eventDate)
        
        // Get default calendar
        guard let calendar = self.eventStore.defaultCalendarForNewEvents else {
            alertTitle = "Error"
            alertMessage = "Could not access default calendar"
            showAlert = true
            return
        }
        
        event.calendar = calendar
        
        do {
            try self.eventStore.save(event, span: .thisEvent)
            self.alertTitle = "Success"
            self.alertMessage = "Event added to calendar"
            self.eventTitle = ""
            
            // Refresh the events list
            fetchEvents()
            // Also refresh the month view
            fetchMonthEvents()
        } catch {
            self.alertTitle = "Error"
            self.alertMessage = "Failed to save event: \(error.localizedDescription)"
        }
        showAlert = true
    }
}

#Preview{
    EventView()
}


