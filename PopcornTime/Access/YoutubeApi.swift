//
//  YoutubeApi.swift
//  PopcornTime
//
//  Created by Alexandru Tudose on 04.08.2021.
//  Copyright © 2021 PopcornTime. All rights reserved.
//

import Foundation

// https://github.com/yt-dlp/yt-dlp/blob/master/yt_dlp/extractor/youtube.py
class YoutubeApi {
    struct Video: Decodable {
        struct Streaming: Decodable {
            struct Formats: Decodable {
                var url: URL
                var qualityLabel: String? // only for video tracks
                var width: Int?
            }
            var formats: [Formats]?
            var hlsManifestUrl: URL?
        }
        
        var streamingData: Streaming
    }
    
    class func getVideo(id: String) async throws -> Video {
//        let body = """
//            {
//             "context": {
//               "client": {
//                "hl": "en",
//                "clientName": "WEB",
//                "clientVersion": "2.20210721.00.00",
//                "mainAppWebInfo": {
//                    "graftUrl": "/watch?v={VIDEO_ID}"
//                }
//               }
//              },
//              "videoId": "{VIDEO_ID}"
//            }
//            """.replacingOccurrences(of: "{VIDEO_ID}", with: id)
//        let url = URL(string: "https://youtubei.googleapis.com/youtubei/v1/player?key=AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8")!
        
        let body = """
            {
             "context": {
               "client": {
                    "clientName": "IOS",
                    "clientVersion": "17.33.2",
                    "deviceModel": "iPhone14,3",
                    "userAgent": "com.google.ios.youtube/17.33.2 (iPhone14,3; U; CPU iOS 15_6 like Mac OS X)"
               }
              },
              "videoId": "{VIDEO_ID}"
            }
            """.replacingOccurrences(of: "{VIDEO_ID}", with: id)
        let url = URL(string: "https://www.youtube.com/youtubei/v1/player?key=AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body.data(using: .utf8)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let video = try JSONDecoder().decode(Video.self, from: data)
    
        return video
        
    }
}
