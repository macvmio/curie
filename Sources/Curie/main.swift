import CurieCommand
import Foundation

func main() -> Int32 {
    CommandRunner().run(with: Array(ProcessInfo.processInfo.arguments.dropFirst()))
}

exit(main())
