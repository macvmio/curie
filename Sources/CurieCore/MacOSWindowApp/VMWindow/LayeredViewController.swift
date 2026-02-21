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

import AppKit

class LayeredViewController: NSViewController {
    private let mainViewController: NSViewController
    private let overlayViewController: NSViewController

    init(mainViewController: NSViewController, overlayViewController: NSViewController) {
        self.mainViewController = mainViewController
        self.overlayViewController = overlayViewController
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addChild(mainViewController)
        view.addSubview(mainViewController.view)
        mainViewController.view.translatesAutoresizingMaskIntoConstraints = false

        addChild(overlayViewController)
        view.addSubview(overlayViewController.view)
        overlayViewController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            mainViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            mainViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            overlayViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            overlayViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}
