# Info.plist keys to add in Xcode

Target → **Info** tab → add these rows (Xcode shows the friendly names below and
writes the raw key in parentheses to the plist for you):

| Key | Value |
|---|---|
| Privacy - Camera Usage Description (`NSCameraUsageDescription`) | "Nexus Demo needs camera access to scan codes, capture photos, and record video." |
| Privacy - Face ID Usage Description (`NSFaceIDUsageDescription`) | "Nexus Demo uses Face ID to let you sign in securely." |
| Privacy - Microphone Usage Description (`NSMicrophoneUsageDescription`) | "Nexus Demo needs microphone access to record audio and video." |
| Privacy - Location When In Use Usage Description (`NSLocationWhenInUseUsageDescription`) | "Nexus Demo uses your location for the GPS test and nearby-provider search." |

Notes:
- Video recording (feature 3) needs **both** Camera and Microphone descriptions, since captured video includes audio.
- The GPS test (feature 8) and Healthcare's Nearby tab need the Location key even though Nearby currently uses sample data — add it now so a real location lookup can be wired in later without a re-crash.
- The file picker (feature 4) uses SwiftUI's built-in `fileImporter`, which needs no extra Info.plist entry.
- The IP geo lookup (feature 6) calls `https://ipapi.co` over plain HTTPS, so no App Transport Security exceptions are needed.
