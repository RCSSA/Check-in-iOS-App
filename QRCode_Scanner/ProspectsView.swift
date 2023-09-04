//
//  ProspectsView.swift
//  HotProspects
//
//  Created by Paul Hudson on 03/01/2022.
//
import CodeScanner
import SwiftUI
import UserNotifications

func convertStringToDictionary(text: String) -> [String:String]? {
   if let data = text.data(using: .utf8) {
       do {
           let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:String]
           return json
       } catch {
           print("Something went wrong")
       }
   }
   return nil
}

// Loading View
struct LoaderView: View {
    var tintColor: Color = .blue
    var scaleSize: CGFloat = 1.0
    
    var body: some View {
        ProgressView()
            .scaleEffect(scaleSize, anchor: .center)
            .progressViewStyle(CircularProgressViewStyle(tint: tintColor))
    }
}


struct ProspectsView: View {
    enum FilterType {
        case none, contacted, uncontacted
    }

    @EnvironmentObject var prospects: Prospects
    @State private var isShowingScanner: Bool = false
    @State private var showingAlert: Bool = false
    @State private var isHideLoader: Bool = true

    let filter: FilterType

    var body: some View {
        VStack {
            if (!isHideLoader)
            {
                LoaderView(tintColor: .blue, scaleSize: 1.0).padding(.bottom)
            }
            NavigationView {
                List {
                    ForEach(filteredProspects) { prospect in
                        VStack(alignment: .leading) {
                            Text(prospect.name)
                                .font(.headline)
                            Text(prospect.emailAddress)
                                .foregroundColor(.secondary)
                        }
                        .swipeActions {
                            Button {
                                prospects.delete(prospect)
                            } label: {
                                Label("Mark removed", systemImage: "trash.slash")
                            }
                            .tint(.red)
                        }
                    }
                }
                .navigationTitle(title)
                .toolbar {
                    Button {
                        isShowingScanner = true
                    } label: {
                        Label("Scan", systemImage: "qrcode.viewfinder")
                    }
                }
                .sheet(isPresented: $isShowingScanner) {
                    CodeScannerView(codeTypes: [.qr], simulatedData: "YWxsZW5oczU2QHJpY2UuZWR1", completion: handleScan)
                }
                .alert("ERROR: Already checked in or not registered", isPresented: $showingAlert) {
                    Button("OK", role: .cancel) { }
                }
            }
        }
    }

    var title: String {
        switch filter {
        case .none:
            return "Checked In"
        case .contacted:
            return "Contacted people"
        case .uncontacted:
            return "Uncontacted people"
        }
    }

    var filteredProspects: [Prospect] {
        switch filter {
        case .none:
            return prospects.people
        case .contacted:
            return prospects.people.filter { $0.isContacted }
        case .uncontacted:
            return prospects.people.filter { !$0.isContacted }
        }
    }

    func handleScan(result: Result<ScanResult, ScanError>) {
        isShowingScanner = false

        switch result {
        case .success(let result):
            let details = result.string
            
            isHideLoader = false
            print("isHideLoader: ", isHideLoader)
            print("result", result)
            let url = URL(string: "https://script.google.com/macros/s/AKfycbwk_SybuCcIV26eIPASozdLdbo2QKh1XE1MNTwUjiPLYoz0upEIQzQ9txBKf5rsKdarCg/exec?action=get&id=" + details)!
            let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
                guard let data = data else { return }
                let res_str = String(data: data, encoding: .utf8)!
                print(res_str)
                let data_dic = convertStringToDictionary(text: res_str)
                let res_status = data_dic!["status"] ?? "ERROR"
                if (res_status == "success") {
                    let person = Prospect()
                    person.name = data_dic!["name"] ?? "ERROR"
                    person.emailAddress = data_dic!["email"] ?? "ERROR"
                    prospects.add(person)
                }
                else {
                    print("ERROR!! USER NOT FOUND!")
                    showingAlert = true
                }
                isHideLoader = true
            }

            task.resume()
        case .failure(let error):
            print("Scanning failed: \(error.localizedDescription)")
        }
    }

    func addNotification(for prospect: Prospect) {
        let center = UNUserNotificationCenter.current()

        let addRequest = {
            let content = UNMutableNotificationContent()
            content.title = "Contact \(prospect.name)"
            content.subtitle = prospect.emailAddress
            content.sound = UNNotificationSound.default

            var dateComponents = DateComponents()
            dateComponents.hour = 9
//            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            center.add(request)
        }

        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                addRequest()
            } else {
                center.requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                    if success {
                        addRequest()
                    } else {
                        print("D'oh!")
                    }
                }
            }
        }
    }
}

struct ProspectsView_Previews: PreviewProvider {
    static var previews: some View {
        ProspectsView(filter: .none)
            .environmentObject(Prospects())
        ProspectsView(filter: .contacted)
            .environmentObject(Prospects())
    }
}
