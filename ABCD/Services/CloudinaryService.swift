//
//  CloudinaryService.swift
//  ABCD
//

import Foundation

final class CloudinaryService {
    struct UploadResponse: Decodable {
        let secure_url: String
    }

    static let shared = CloudinaryService()

    private init() {}

    func uploadImage(data: Data, fileNamePrefix: String, completion: @escaping (Result<String, Error>) -> Void) {
        let cloudName = Constants.Cloudinary.cloudName
        let preset = Constants.Cloudinary.unsignedUploadPreset

        guard !cloudName.isEmpty, !preset.isEmpty, preset != "YOUR_UNSIGNED_PRESET" else {
            completion(.failure(NSError(
                domain: "Cloudinary",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Cloudinary upload preset is not configured."]
            )))
            return
        }

        guard let url = URL(string: "https://api.cloudinary.com/v1_1/\(cloudName)/image/upload") else {
            completion(.failure(NSError(
                domain: "Cloudinary",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Invalid Cloudinary upload URL."]
            )))
            return
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        addFormField("upload_preset", value: preset, to: &body, boundary: boundary)
        addFormField("folder", value: Constants.Cloudinary.uploadsFolder, to: &body, boundary: boundary)
        addFormField("public_id", value: "\(fileNamePrefix)_\(UUID().uuidString)", to: &body, boundary: boundary)
        addFileField(
            named: "file",
            fileName: "\(fileNamePrefix).jpg",
            mimeType: "image/jpeg",
            fileData: data,
            to: &body,
            boundary: boundary
        )
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error {
                completion(.failure(error))
                return
            }

            guard let data else {
                completion(.failure(NSError(
                    domain: "Cloudinary",
                    code: -3,
                    userInfo: [NSLocalizedDescriptionKey: "Empty response from Cloudinary."]
                )))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(UploadResponse.self, from: data)
                completion(.success(decoded.secure_url))
            } catch {
                let raw = String(data: data, encoding: .utf8) ?? "Unknown response"
                completion(.failure(NSError(
                    domain: "Cloudinary",
                    code: -4,
                    userInfo: [NSLocalizedDescriptionKey: "Cloudinary upload failed: \(raw)"]
                )))
            }
        }.resume()
    }

    private func addFormField(_ name: String, value: String, to body: inout Data, boundary: String) {
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(value)\r\n".data(using: .utf8)!)
    }

    private func addFileField(named name: String, fileName: String, mimeType: String, fileData: Data, to body: inout Data, boundary: String) {
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
    }
}
