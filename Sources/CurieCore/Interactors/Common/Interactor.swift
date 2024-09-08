import CurieCommon

//public protocol Interactor {
//    associatedtype Context
//    
//    func execute(context: Context) throws
//}

protocol AsyncInteractor: AnyObject {
    associatedtype Context
    
    func execute(context: Context, runLoop: RunLoopAccessor) async throws
}

final class AsyncInteractorAdapter<Interactor: AsyncInteractor> {
    private let interactor: Interactor
    private let runLoop: CurieCommon.RunLoop
    
    init(interactor: Interactor, runLoop: CurieCommon.RunLoop) {
        self.interactor = interactor
        self.runLoop = runLoop
    }

    func execute(context: Interactor.Context) throws {
        try runLoop.run { [self] _ in
            try await interactor.execute(context: context, runLoop: runLoop)
        }
    }
}
