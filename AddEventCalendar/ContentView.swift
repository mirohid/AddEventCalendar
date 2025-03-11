//
//  ContentView.swift
//  AddEventCalendar
//
//  Created by MacMini6 on 11/03/25.
//

import SwiftUI
import EventKit

struct ContentView: View {
    @State private var eventTitle: String = ""
    @State private var eventDate: Date = Date()
    private let eventStore = EKEventStore()
    
    var body: some View {
        VStack(spacing: 20) {
            DatePicker("Select Date", selection: $eventDate, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
            
            TextField("Enter Event Title", text: $eventTitle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Add to Calendar") {
                requestCalendarAccess()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
    
    func requestCalendarAccess() {
        eventStore.requestAccess(to: .event) { granted, error in
            if granted {
                addEventToCalendar()
            } else {
                print("Access Denied: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    func addEventToCalendar() {
        let event = EKEvent(eventStore: eventStore)
        event.title = eventTitle
        event.startDate = eventDate
        event.endDate = eventDate.addingTimeInterval(3600) // 1-hour event
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        do {
            try eventStore.save(event, span: .thisEvent)
            print("Event Added Successfully")
        } catch {
            print("Error saving event: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ContentView()
}
