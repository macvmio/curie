//
// Copyright 2026 Marcin Iwanicki, Tomasz Jarosik, and contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

public enum KeyPhase: String, Codable {
    /// Down alone is generally used to enable key modifier (e.g. shift + <other key while shift is pressed>)
    /// The event flow would be:  down (for shift) -> press (for other keys) -> up (for shift)
    case down

    /// Up alone is used to release key modifier
    case up // swiftlint:disable:this identifier_name

    /// Regular key press (down and then up)
    case press
}
