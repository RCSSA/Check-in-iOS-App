//
//  MeView.swift
//  HotProspects
//
//  Created by Paul Hudson on 03/01/2022.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI

struct MeView: View {
//    @State private var name = "James"
//    @State private var emailAddress = "xxx@xxx"
//    @State private var name = "tim"
//    @State private var emailAddress = "wz51@rice.edu"
    @State private var uuid = "1234"
    @State private var qrCode = UIImage()

    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()

    var body: some View {
        NavigationView {
            Form {
//                TextField("Name", text: $name)
//                    .textContentType(.name)
//                    .font(.title)
//
//                TextField("Email address", text: $emailAddress)
//                    .textContentType(.emailAddress)
//                    .font(.title)
                Text("UUID: \(uuid)")
                        .font(.title)
                        .padding()

                Image(uiImage: qrCode)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .contextMenu {
                        Button {
                            let imageSaver = ImageSaver()
                            imageSaver.writeToPhotoAlbum(image: qrCode)
                        } label: {
                            Label("Save to Photos", systemImage: "square.and.arrow.down")
                        }
                    }
            }
            .navigationTitle("Your code")
            .onAppear(perform: updateCode)
//            .onChange(of: name) { _ in updateCode() }
//            .onChange(of: emailAddress) { _ in updateCode() }
        }
    }

    func updateCode() {
        qrCode = generateQRCode(from: "\(uuid)")
    }

    func generateQRCode(from string: String) -> UIImage {
        filter.message = Data(string.utf8)

        if let outputImage = filter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgimg)
            }
        }

        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}

struct MeView_Previews: PreviewProvider {
    static var previews: some View {
        MeView()
    }
}
