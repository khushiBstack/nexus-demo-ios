import SwiftUI
import CoreLocation
import Combine
import PassKit
import UniformTypeIdentifiers

// MARK: - Brand colour

extension Color {
    static let care       = Color(red: 0.18, green: 0.55, blue: 0.50)
    static let careSoft   = Color(red: 0.18, green: 0.55, blue: 0.50).opacity(0.10)
    static let careSubtle = Color(red: 0.18, green: 0.55, blue: 0.50).opacity(0.18)
}

// MARK: - Models

struct Appointment: Identifiable {
    let id = UUID()
    let doctor: String
    let specialty: String
    let date: Date
    let suite: String
    var isPaid: Bool = false
    var paymentMethod: String = ""
    let fee: Double
}

struct HealthRecord: Identifiable {
    let id = UUID()
    let title: String
    let date: Date
    let type: String
}

struct Prescription: Identifiable {
    let id = UUID()
    let medication: String
    let dosage: String
    let doctor: String
    let date: Date
    var fileUploaded: Bool = false
}

struct LabResult: Identifiable {
    let id = UUID()
    let testName: String
    let date: Date
    let status: String
    let summary: String
}

struct NearbyProvider: Identifiable {
    let id = UUID()
    let name: String
    let distance: String
    let type: String
}

enum HealthcareSampleData {
    static let appointments: [Appointment] = [
        Appointment(doctor: "Dr. Sarah Chen", specialty: "Cardiology",
                    date: .now.addingTimeInterval(86400), suite: "Suite 4B", fee: 150),
        Appointment(doctor: "Dr. Marcus Lee", specialty: "General Physician",
                    date: .now.addingTimeInterval(86400 * 5), suite: "Suite 2A", fee: 80)
    ]
    static let records: [HealthRecord] = [
        HealthRecord(title: "Blood Test Results", date: .now.addingTimeInterval(-86400 * 10), type: "Lab Report"),
        HealthRecord(title: "Annual Physical",    date: .now.addingTimeInterval(-86400 * 40), type: "Visit Summary"),
        HealthRecord(title: "Vaccination Record", date: .now.addingTimeInterval(-86400 * 120), type: "Immunization")
    ]
    static let prescriptions: [Prescription] = [
        Prescription(medication: "Metformin 500mg", dosage: "Twice daily", doctor: "Dr. Sarah Chen",
                     date: .now.addingTimeInterval(-86400 * 7)),
        Prescription(medication: "Lisinopril 10mg", dosage: "Once daily", doctor: "Dr. Marcus Lee",
                     date: .now.addingTimeInterval(-86400 * 30))
    ]
    static let labResults: [LabResult] = [
        LabResult(testName: "Complete Blood Count", date: .now.addingTimeInterval(-86400 * 5),
                  status: "Normal", summary: "All values within normal range."),
        LabResult(testName: "HbA1c", date: .now.addingTimeInterval(-86400 * 10),
                  status: "Borderline", summary: "5.9% — monitor diet and exercise."),
        LabResult(testName: "Lipid Panel", date: .now.addingTimeInterval(-86400 * 20),
                  status: "Normal", summary: "LDL 98, HDL 62, Triglycerides 140.")
    ]
    static let nearby: [NearbyProvider] = [
        NearbyProvider(name: "Downtown Urgent Care",  distance: "0.8 mi", type: "Urgent Care"),
        NearbyProvider(name: "City General Hospital", distance: "1.4 mi", type: "Hospital"),
        NearbyProvider(name: "Wellness Pharmacy",     distance: "0.3 mi", type: "Pharmacy")
    ]
}

// MARK: - Root

struct HealthcareRootView: View {
    @EnvironmentObject var session: SessionStore
    var body: some View {
        Group {
            if session.healthcareLoggedIn && session.healthcareOTPVerified {
                HealthcareTabView().toolbar(.hidden, for: .navigationBar)
            } else if session.healthcareLoggedIn && !session.healthcareOTPVerified {
                OTPVerificationView(title: "CareNexus", tint: Color.care, icon: "cross.case.fill") {
                    session.healthcareOTPVerified = true
                }
            } else {
                IndustryLoginView(title: "CareNexus", icon: "cross.case.fill", tint: Color.care) { email, name in
                    session.healthcareUserEmail = email
                    session.healthcareUserName = name
                    session.healthcareLoggedIn = true
                    session.healthcareOTPVerified = false
                }
            }
        }
        .navigationTitle("Healthcare")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Tab View

struct HealthcareTabView: View {
    @EnvironmentObject var session: SessionStore
    @State private var appointments: [Appointment] = HealthcareSampleData.appointments
    var body: some View {
        TabView {
            NavigationStack { PatientHomeView(appointments: $appointments) }
                .tabItem { Label("Home", systemImage: "house.fill") }
            NavigationStack { AppointmentsView(appointments: $appointments) }
                .tabItem { Label("Appointments", systemImage: "calendar.badge.plus") }
            NavigationStack { RecordsView() }
                .tabItem { Label("Records", systemImage: "doc.text.fill") }
            NavigationStack { NearbyView() }
                .tabItem { Label("Nearby", systemImage: "location.fill") }
            NavigationStack {
                ProfileView(domainName: "Healthcare") {
                    session.healthcareLoggedIn = false
                    session.healthcareUserName = ""
                    session.healthcareUserEmail = ""
                    session.healthcareOTPVerified = false
                }
            }.tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
        .tint(Color.care)
    }
}

// MARK: - Patient Home

struct PatientHomeView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var geo: IPGeoManager
    @Environment(\.dismiss) private var dismiss
    @Binding var appointments: [Appointment]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hello, \(session.healthcareUserName.isEmpty ? "Patient" : session.healthcareUserName)")
                            .font(.title2.bold())
                        Text("Stay healthy today").font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer()
                    NetworkSpeedWidget()
                }
                .padding(.horizontal).padding(.top)

                // Quick actions
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()),
                                    GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    CareQuickAction(title: "Book", icon: "calendar.badge.plus", tint: Color.care)
                    CareQuickAction(title: "Records", icon: "doc.text.fill", tint: .blue)
                    CareQuickAction(title: "Rx", icon: "pills.fill", tint: .orange)
                    CareQuickAction(title: "Labs", icon: "flask.fill", tint: .purple)
                }.padding(.horizontal)

                // Upcoming appointments
                let upcoming = appointments.filter { $0.date > Date() }
                if !upcoming.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Upcoming Appointments").font(.headline).padding(.horizontal)
                        ForEach(upcoming.prefix(2)) { appt in
                            NavigationLink(destination: AppointmentDetailView(
                                appointment: appt,
                                onPaid: { method in
                                    if let idx = appointments.firstIndex(where: { $0.id == appt.id }) {
                                        appointments[idx].isPaid = true
                                        appointments[idx].paymentMethod = method
                                    }
                                }
                            )) {
                                AppointmentCard(appointment: appt)
                            }.buttonStyle(.plain).padding(.horizontal)
                        }
                    }
                }

                // Lab results
                VStack(alignment: .leading, spacing: 10) {
                    Text("Recent Lab Results").font(.headline).padding(.horizontal)
                    ForEach(HealthcareSampleData.labResults.prefix(2)) { result in
                        NavigationLink(destination: LabResultDetailView(result: result)) {
                            LabResultCard(result: result)
                        }.buttonStyle(.plain).padding(.horizontal)
                    }
                }

                // Prescriptions
                VStack(alignment: .leading, spacing: 10) {
                    Text("Active Prescriptions").font(.headline).padding(.horizontal)
                    ForEach(HealthcareSampleData.prescriptions) { rx in
                        NavigationLink(destination: PrescriptionDetailView(prescription: rx)) {
                            PrescriptionCard(prescription: rx)
                        }.buttonStyle(.plain).padding(.horizontal)
                    }
                }
            }.padding(.bottom, 24)
        }
        .navigationTitle("CareNexus")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { geo.fetchIfNeeded() }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left.square.fill")
                        .font(.title3).foregroundStyle(Color.care)
                }.accessibilityLabel("Back to domains")
            }
        }
    }
}

struct CareQuickAction: View {
    let title: String; let icon: String; let tint: Color
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 14).fill(tint.opacity(0.12)).frame(height: 52)
                Image(systemName: icon).font(.title3).foregroundStyle(tint).accessibilityHidden(true)
            }
            Text(title).font(.caption.weight(.medium)).foregroundStyle(.primary)
        }.accessibilityLabel(title)
    }
}

// MARK: - Appointments

struct AppointmentsView: View {
    @Binding var appointments: [Appointment]
    @State private var showBooking = false
    var body: some View {
        List {
            Section("Upcoming") {
                ForEach(appointments.indices.filter { appointments[$0].date > Date() }, id: \.self) { idx in
                    NavigationLink(destination: AppointmentDetailView(
                        appointment: appointments[idx],
                        onPaid: { method in appointments[idx].isPaid = true; appointments[idx].paymentMethod = method }
                    )) {
                        AppointmentRow(appointment: appointments[idx])
                    }
                }
            }
            Section("Past") {
                ForEach(appointments.filter { $0.date <= Date() }) { appt in
                    AppointmentRow(appointment: appt)
                }
            }
        }
        .navigationTitle("Appointments")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showBooking = true } label: {
                    Image(systemName: "plus.circle.fill").foregroundStyle(Color.care)
                }.accessibilityLabel("Book appointment")
            }
        }
        .sheet(isPresented: $showBooking) {
            BookAppointmentSheet { newAppt in appointments.append(newAppt) }
        }
    }
}

struct AppointmentRow: View {
    let appointment: Appointment
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Color.careSoft).frame(width: 44, height: 44)
                Image(systemName: "stethoscope").foregroundStyle(Color.care).accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(appointment.doctor).font(.subheadline.weight(.semibold))
                Text(appointment.specialty).font(.caption).foregroundStyle(.secondary)
                Text(appointment.date, style: .date).font(.caption2).foregroundStyle(.tertiary)
            }
            Spacer()
            if appointment.isPaid {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    .accessibilityLabel("Paid")
            } else {
                Text(appointment.fee, format: .currency(code: "USD"))
                    .font(.caption.bold()).foregroundStyle(Color.care)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(appointment.doctor + ", " + appointment.specialty)
    }
}

struct AppointmentCard: View {
    let appointment: Appointment
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Color.careSoft).frame(width: 52, height: 52)
                Image(systemName: "stethoscope").font(.title3).foregroundStyle(Color.care).accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(appointment.doctor).font(.subheadline.weight(.semibold))
                Text(appointment.specialty).font(.caption).foregroundStyle(.secondary)
                Label(appointment.date.formatted(date: .abbreviated, time: .shortened),
                      systemImage: "calendar").font(.caption2).foregroundStyle(Color.care)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(appointment.fee, format: .currency(code: "USD")).font(.caption.bold()).foregroundStyle(Color.care)
                Text(appointment.isPaid ? "Paid" : "Unpaid").font(.caption2)
                    .foregroundStyle(appointment.isPaid ? .green : .orange)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

// MARK: - Appointment Detail + Payment

struct AppointmentDetailView: View {
    let appointment: Appointment
    let onPaid: (String) -> Void
    @State private var paymentDone: Bool
    @State private var paymentMethod = "Card"

    init(appointment: Appointment, onPaid: @escaping (String) -> Void) {
        self.appointment = appointment
        self.onPaid = onPaid
        _paymentDone = State(initialValue: appointment.isPaid)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero
                ZStack {
                    LinearGradient(colors: [Color.care, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .frame(height: 140).clipShape(RoundedRectangle(cornerRadius: 20))
                    VStack(spacing: 6) {
                        Image(systemName: "stethoscope").font(.system(size: 36)).foregroundStyle(.white).accessibilityHidden(true)
                        Text(appointment.doctor).font(.title3.bold()).foregroundStyle(.white)
                        Text(appointment.specialty).font(.subheadline).foregroundStyle(.white.opacity(0.85))
                    }
                }.padding(.horizontal)

                // Details
                VStack(spacing: 0) {
                    CareDetailRow(label: "Date", value: appointment.date.formatted(date: .long, time: .shortened))
                    Divider().padding(.leading, 16)
                    CareDetailRow(label: "Location", value: appointment.suite)
                    Divider().padding(.leading, 16)
                    CareDetailRow(label: "Consultation Fee", value: appointment.fee.formatted(.currency(code: "USD")), valueColor: Color.care)
                }
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                .padding(.horizontal)

                if paymentDone {
                    // Confirmation + receipt
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill").font(.system(size: 48)).foregroundStyle(.green).accessibilityHidden(true)
                        Text("Payment Confirmed").font(.title2.bold())
                        Text("Paid via \(paymentMethod)").font(.caption).foregroundStyle(.secondary)
                        Button {
                            if let url = generateHealthcareReceiptPDF(appointment: appointment, paymentMethod: paymentMethod) { presentShareSheet(url: url) }
                        } label: {
                            Label("Download Receipt (PDF)", systemImage: "arrow.down.doc.fill")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity).padding(.vertical, 10)
                                .background(Color.green.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                                .foregroundStyle(.green)
                        }
                        .accessibilityLabel("Download receipt as PDF")
                    }
                    .frame(maxWidth: .infinity).padding()
                    .background(Color.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                } else {
                    CarePaymentButtons(total: appointment.fee, tint: Color.care) { method in
                        paymentMethod = method
                        onPaid(method)
                        paymentDone = true
                    }
                    .padding(.horizontal)
                }
            }.padding(.vertical)
        }
        .navigationTitle("Appointment").navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Book Appointment Sheet

struct BookAppointmentSheet: View {
    let onBook: (Appointment) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var doctor = ""
    @State private var specialty = "General Physician"
    @State private var date = Date().addingTimeInterval(86400 * 3)
    @State private var suite = "Suite 1A"
    let specialties = ["General Physician", "Cardiology", "Dermatology", "Orthopedics", "Neurology", "Pediatrics"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Doctor") {
                    TextField("Doctor name", text: $doctor).accessibilityLabel("Doctor name")
                    Picker("Specialty", selection: $specialty) {
                        ForEach(specialties, id: \.self) { Text($0).tag($0) }
                    }
                }
                Section("Schedule") {
                    DatePicker("Date & Time", selection: $date, in: Date()...).accessibilityLabel("Appointment date and time")
                    TextField("Suite / Room", text: $suite).accessibilityLabel("Suite or room number")
                }
                Section {
                    Button("Book Appointment") {
                        let appt = Appointment(
                            doctor: doctor.isEmpty ? "Dr. New Doctor" : doctor,
                            specialty: specialty,
                            date: date,
                            suite: suite.isEmpty ? "Suite 1A" : suite,
                            fee: 100
                        )
                        onBook(appt)
                        dismiss()
                    }
                    .foregroundStyle(Color.care)
                    .accessibilityLabel("Confirm booking")
                }
            }
            .navigationTitle("Book Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Records View (upload + download)

struct RecordsView: View {
    @State private var records: [HealthRecord] = HealthcareSampleData.records
    @State private var showUploadPicker = false
    @State private var uploadedFileName: String?

    var body: some View {
        List {
            Section {
                Button {
                    showUploadPicker = true
                } label: {
                    Label("Upload Medical Record", systemImage: "arrow.up.doc.fill")
                        .foregroundStyle(Color.care)
                }
                .accessibilityLabel("Upload a medical record file")
                if let name = uploadedFileName {
                    Label("Uploaded: \(name)", systemImage: "checkmark.circle.fill")
                        .font(.caption).foregroundStyle(.green)
                }
            }

            Section("My Records") {
                ForEach(records) { record in
                    HStack(spacing: 14) {
                        ZStack {
                            Circle().fill(Color.careSoft).frame(width: 40, height: 40)
                            Image(systemName: "doc.text.fill").foregroundStyle(Color.care).accessibilityHidden(true)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(record.title).font(.subheadline.weight(.semibold))
                            Text(record.type).font(.caption).foregroundStyle(.secondary)
                            Text(record.date, style: .date).font(.caption2).foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Button {
                            if let url = generateHealthRecordPDF(record: record) { presentShareSheet(url: url) }
                        } label: {
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundStyle(Color.care)
                        }
                        .accessibilityLabel("Download \(record.title)")
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(record.title + ", " + record.type)
                }
            }
        }
        .navigationTitle("Health Records")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showUploadPicker) {
            DocumentPickerView { name in uploadedFileName = name }
        }
    }
}

// MARK: - Lab Results

struct LabResultCard: View {
    let result: LabResult
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(Color.purple.opacity(0.10)).frame(width: 44, height: 44)
                Image(systemName: "flask.fill").foregroundStyle(.purple).accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(result.testName).font(.subheadline.weight(.semibold))
                Text(result.date, style: .date).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(result.status).font(.caption2).padding(.horizontal, 8).padding(.vertical, 3)
                .background(result.status == "Normal" ? Color.green.opacity(0.12) : Color.orange.opacity(0.12), in: Capsule())
                .foregroundStyle(result.status == "Normal" ? .green : .orange)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

struct LabResultDetailView: View {
    let result: LabResult
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ZStack {
                    LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .frame(height: 120).clipShape(RoundedRectangle(cornerRadius: 20))
                    VStack(spacing: 6) {
                        Image(systemName: "flask.fill").font(.system(size: 32)).foregroundStyle(.white).accessibilityHidden(true)
                        Text(result.testName).font(.title3.bold()).foregroundStyle(.white)
                    }
                }.padding(.horizontal)

                VStack(spacing: 0) {
                    CareDetailRow(label: "Date", value: result.date.formatted(date: .long, time: .omitted))
                    Divider().padding(.leading, 16)
                    CareDetailRow(label: "Status", value: result.status,
                                  valueColor: result.status == "Normal" ? .green : .orange)
                    Divider().padding(.leading, 16)
                    CareDetailRow(label: "Summary", value: result.summary)
                }
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                .padding(.horizontal)

                Button {
                    if let url = generateLabReportPDF(result: result) { presentShareSheet(url: url) }
                } label: {
                    Label("Download Lab Report (PDF)", systemImage: "arrow.down.doc.fill")
                        .font(.headline).frame(maxWidth: .infinity).padding()
                        .background(Color.purple, in: RoundedRectangle(cornerRadius: 14)).foregroundStyle(.white)
                }
                .padding(.horizontal)
                .accessibilityLabel("Download lab report as PDF")
            }.padding(.vertical)
        }
        .navigationTitle("Lab Result").navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Prescriptions

struct PrescriptionCard: View {
    let prescription: Prescription
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(Color.orange.opacity(0.10)).frame(width: 44, height: 44)
                Image(systemName: "pills.fill").foregroundStyle(.orange).accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(prescription.medication).font(.subheadline.weight(.semibold))
                Text(prescription.dosage).font(.caption).foregroundStyle(.secondary)
                Text(prescription.doctor).font(.caption2).foregroundStyle(.tertiary)
            }
            Spacer()
            if prescription.fileUploaded {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    .accessibilityLabel("File uploaded")
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

struct PrescriptionDetailView: View {
    let prescription: Prescription
    @State private var fileUploaded = false
    @State private var uploadedFileName: String?
    @State private var showUploadPicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ZStack {
                    LinearGradient(colors: [.orange, Color(red: 0.9, green: 0.4, blue: 0.1)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                        .frame(height: 120).clipShape(RoundedRectangle(cornerRadius: 20))
                    VStack(spacing: 6) {
                        Image(systemName: "pills.fill").font(.system(size: 32)).foregroundStyle(.white).accessibilityHidden(true)
                        Text(prescription.medication).font(.title3.bold()).foregroundStyle(.white)
                    }
                }.padding(.horizontal)

                VStack(spacing: 0) {
                    CareDetailRow(label: "Dosage", value: prescription.dosage)
                    Divider().padding(.leading, 16)
                    CareDetailRow(label: "Prescribed by", value: prescription.doctor)
                    Divider().padding(.leading, 16)
                    CareDetailRow(label: "Date", value: prescription.date.formatted(date: .long, time: .omitted))
                }
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                .padding(.horizontal)

                VStack(spacing: 12) {
                    Button { showUploadPicker = true } label: {
                        Label(fileUploaded ? "Replace Prescription File" : "Upload Prescription File",
                              systemImage: "arrow.up.doc.fill")
                            .font(.headline).frame(maxWidth: .infinity).padding()
                            .background(Color.orange, in: RoundedRectangle(cornerRadius: 14)).foregroundStyle(.white)
                    }.accessibilityLabel("Upload prescription file")

                    if let name = uploadedFileName {
                        Label("Uploaded: \(name)", systemImage: "checkmark.circle.fill")
                            .font(.caption).foregroundStyle(.green)
                    }

                    Button {
                        if let url = generatePrescriptionPDF(prescription: prescription) { presentShareSheet(url: url) }
                    } label: {
                        Label("Download Prescription (PDF)", systemImage: "arrow.down.doc.fill")
                            .font(.headline).frame(maxWidth: .infinity).padding()
                            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(Color.orange)
                    }.accessibilityLabel("Download prescription as PDF")
                }.padding(.horizontal)
            }.padding(.vertical)
        }
        .navigationTitle("Prescription").navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showUploadPicker) {
            DocumentPickerView { name in uploadedFileName = name; fileUploaded = true }
        }
    }
}

// MARK: - Nearby

final class HealthcareLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let mgr = CLLocationManager()
    private let geocoder = CLGeocoder()
    @Published var city: String?
    @Published var authStatus: CLAuthorizationStatus = .notDetermined
    override init() { super.init(); mgr.delegate = self; authStatus = mgr.authorizationStatus }
    func requestLocation() { mgr.requestWhenInUseAuthorization(); mgr.requestLocation() }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.first else { return }
        geocoder.reverseGeocodeLocation(loc) { [weak self] placemarks, _ in
            DispatchQueue.main.async { self?.city = placemarks?.first?.locality }
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async { self.authStatus = manager.authorizationStatus }
    }
}

struct NearbyProviderRow: View {
    let provider: NearbyProvider
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Color.careSoft).frame(width: 40, height: 40)
                Image(systemName: provider.type == "Hospital" ? "building.2.fill" :
                      provider.type == "Pharmacy" ? "pills.fill" : "cross.case.fill")
                    .foregroundStyle(Color.care).accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(provider.name).font(.subheadline.weight(.semibold))
                Text(provider.type).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(provider.distance).font(.caption.bold()).foregroundStyle(Color.care)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(provider.name + ", " + provider.type + ", " + provider.distance)
    }
}

struct NearbyView: View {
    @StateObject private var locationMgr = HealthcareLocationManager()
    @EnvironmentObject var geo: IPGeoManager
    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "location.circle.fill").foregroundStyle(Color.care).accessibilityHidden(true)
                    let displayCity = locationMgr.city ?? geo.city ?? geo.country
                    Text(displayCity != nil ? "Showing providers near " + displayCity! : "Tap to find providers near you")
                        .font(.subheadline)
                    Spacer()
                    Button("Locate") { locationMgr.requestLocation() }.tint(Color.care)
                        .accessibilityLabel("Find nearby providers")
                }
            }
            Section("Nearby Providers") {
                ForEach(HealthcareSampleData.nearby) { NearbyProviderRow(provider: $0) }
            }
        }
        .navigationTitle("Nearby").navigationBarTitleDisplayMode(.inline)
        .onAppear { locationMgr.requestLocation(); geo.fetchIfNeeded() }
    }
}

// MARK: - Shared Care Payment

struct CarePaymentButtons: View {
    let total: Double
    let tint: Color
    let onPaid: (String) -> Void
    var body: some View {
        VStack(spacing: 12) {
            CareApplePayButton(total: total) { success in if success { onPaid("Apple Pay") } }
                .frame(maxWidth: .infinity, minHeight: 50)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .accessibilityLabel("Pay with Apple Pay")
            Button { onPaid("Card") } label: {
                Text("Pay \(total.formatted(.currency(code: "USD"))) with Card")
                    .font(.headline).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(tint, in: RoundedRectangle(cornerRadius: 12))
            }.accessibilityLabel("Pay with card")
        }
    }
}

struct CareApplePayButton: UIViewRepresentable {
    let total: Double
    let onResult: (Bool) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(onResult: onResult) }
    func makeUIView(context: Context) -> PKPaymentButton {
        let btn = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .black)
        btn.addTarget(context.coordinator, action: #selector(Coordinator.tapped), for: .touchUpInside)
        context.coordinator.total = total
        return btn
    }
    func updateUIView(_ uiView: PKPaymentButton, context: Context) { context.coordinator.total = total }
    final class Coordinator: NSObject, PKPaymentAuthorizationControllerDelegate {
        var total: Double = 0
        let onResult: (Bool) -> Void
        init(onResult: @escaping (Bool) -> Void) { self.onResult = onResult }
        @objc func tapped() {
            let request = PKPaymentRequest()
            request.merchantIdentifier = "merchant.com.bstack.nexus-demo"
            request.supportedNetworks = [.visa, .masterCard, .amex]
            request.merchantCapabilities = .capability3DS
            request.countryCode = "US"; request.currencyCode = "USD"
            request.paymentSummaryItems = [PKPaymentSummaryItem(label: "CareNexus",
                amount: NSDecimalNumber(string: String(format: "%.2f", (total * 100).rounded() / 100)))]
            let controller = PKPaymentAuthorizationController(paymentRequest: request)
            controller.delegate = self; controller.present(completion: nil)
        }
        func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController,
                                            didAuthorizePayment payment: PKPayment,
                                            handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
            completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
        }
        func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
            controller.dismiss { DispatchQueue.main.async { self.onResult(true) } }
        }
    }
}

// MARK: - Shared Detail Row

struct CareDetailRow: View {
    let label: String; let value: String; var valueColor: Color = .primary
    var body: some View {
        HStack {
            Text(label).foregroundStyle(.secondary).padding(.leading, 16)
            Spacer()
            Text(value).fontWeight(.medium).foregroundStyle(valueColor).padding(.trailing, 16)
        }.frame(minHeight: 44)
    }
}

// MARK: - Document Picker (upload)

struct DocumentPickerView: UIViewControllerRepresentable {
    let onPick: (String) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .image, .data])
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (String) -> Void
        init(onPick: @escaping (String) -> Void) { self.onPick = onPick }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first { onPick(url.lastPathComponent) }
        }
    }
}

// MARK: - PDF Generators

func generateHealthcareReceiptPDF(appointment: Appointment, paymentMethod: String) -> URL? {
    let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
    let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
    let data = renderer.pdfData { ctx in
        ctx.beginPage()
        let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14)]
        let bold: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 16)]
        var y: CGFloat = 40
        func draw(_ text: String, b: Bool = false) {
            text.draw(at: CGPoint(x: 40, y: y), withAttributes: b ? bold : attrs); y += 22
        }
        draw("CareNexus — Appointment Receipt", b: true)
        draw("Doctor: \(appointment.doctor)")
        draw("Specialty: \(appointment.specialty)")
        draw("Date: \(appointment.date.formatted(date: .long, time: .shortened))")
        draw("Suite: \(appointment.suite)")
        draw("Payment: \(paymentMethod)")
        let amt = appointment.fee.formatted(.currency(code: "USD")); draw("Amount: \(amt)", b: true)
    }
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("CareNexus_Receipt.pdf")
    try? data.write(to: url); return url
}

func generateHealthRecordPDF(record: HealthRecord) -> URL? {
    let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
    let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
    let data = renderer.pdfData { ctx in
        ctx.beginPage()
        let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14)]
        let bold: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 16)]
        var y: CGFloat = 40
        func draw(_ text: String, b: Bool = false) {
            text.draw(at: CGPoint(x: 40, y: y), withAttributes: b ? bold : attrs); y += 22
        }
        draw("CareNexus — Health Record", b: true)
        draw(record.title, b: true)
        draw("Type: \(record.type)")
        draw("Date: \(record.date.formatted(date: .long, time: .omitted))")
    }
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("HealthRecord.pdf")
    try? data.write(to: url); return url
}

func generateLabReportPDF(result: LabResult) -> URL? {
    let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
    let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
    let data = renderer.pdfData { ctx in
        ctx.beginPage()
        let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14)]
        let bold: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 16)]
        var y: CGFloat = 40
        func draw(_ text: String, b: Bool = false) {
            text.draw(at: CGPoint(x: 40, y: y), withAttributes: b ? bold : attrs); y += 22
        }
        draw("CareNexus — Lab Report", b: true)
        draw(result.testName, b: true)
        draw("Date: \(result.date.formatted(date: .long, time: .omitted))")
        draw("Status: \(result.status)")
        draw("Summary: \(result.summary)")
    }
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("LabReport.pdf")
    try? data.write(to: url); return url
}

func generatePrescriptionPDF(prescription: Prescription) -> URL? {
    let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
    let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
    let data = renderer.pdfData { ctx in
        ctx.beginPage()
        let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14)]
        let bold: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 16)]
        var y: CGFloat = 40
        func draw(_ text: String, b: Bool = false) {
            text.draw(at: CGPoint(x: 40, y: y), withAttributes: b ? bold : attrs); y += 22
        }
        draw("CareNexus — Prescription", b: true)
        draw(prescription.medication, b: true)
        draw("Dosage: \(prescription.dosage)")
        draw("Prescribed by: \(prescription.doctor)")
        draw("Date: \(prescription.date.formatted(date: .long, time: .omitted))")
    }
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("Prescription.pdf")
    try? data.write(to: url); return url
}


func presentShareSheet(url: URL) {
    guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else { return }
    var top = root
    while let presented = top.presentedViewController { top = presented }
    let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
    // On iPad the activity controller is a popover and crashes without an anchor.
    if let popover = vc.popoverPresentationController {
        popover.sourceView = top.view
        popover.sourceRect = CGRect(x: top.view.bounds.midX, y: top.view.bounds.midY, width: 0, height: 0)
        popover.permittedArrowDirections = []
    }
    top.present(vc, animated: true)
}


#Preview {
    NavigationStack { HealthcareRootView() }
        .environmentObject(SessionStore())
        .environmentObject(IPGeoManager.shared)
}
