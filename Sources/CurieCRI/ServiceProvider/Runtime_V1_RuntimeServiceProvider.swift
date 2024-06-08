import Foundation
import GRPC
import NIO

final class DefaultRuntime_V1_RuntimeServiceProvider: Runtime_V1_RuntimeServiceProvider {
    var interceptors: (any Runtime_V1_RuntimeServiceServerInterceptorFactoryProtocol)?

    func version(request _: Runtime_V1_VersionRequest, context _: any GRPC.StatusOnlyCallContext) -> NIOCore
        .EventLoopFuture<Runtime_V1_VersionResponse> {
        fatalError("Not implemented yet")
    }

    func runPodSandbox(request _: Runtime_V1_RunPodSandboxRequest, context _: any GRPC.StatusOnlyCallContext) -> NIOCore
        .EventLoopFuture<Runtime_V1_RunPodSandboxResponse> {
        fatalError("Not implemented yet")
    }

    func stopPodSandbox(
        request _: Runtime_V1_StopPodSandboxRequest,
        context _: any GRPC.StatusOnlyCallContext
    ) -> NIOCore.EventLoopFuture<Runtime_V1_StopPodSandboxResponse> {
        fatalError("Not implemented yet")
    }

    func removePodSandbox(
        request _: Runtime_V1_RemovePodSandboxRequest,
        context _: any GRPC.StatusOnlyCallContext
    ) -> NIOCore.EventLoopFuture<Runtime_V1_RemovePodSandboxResponse> {
        fatalError("Not implemented yet")
    }

    func podSandboxStatus(
        request _: Runtime_V1_PodSandboxStatusRequest,
        context _: any GRPC.StatusOnlyCallContext
    ) -> NIOCore.EventLoopFuture<Runtime_V1_PodSandboxStatusResponse> {
        fatalError("Not implemented yet")
    }

    func listPodSandbox(
        request _: Runtime_V1_ListPodSandboxRequest,
        context _: any GRPC.StatusOnlyCallContext
    ) -> NIOCore.EventLoopFuture<Runtime_V1_ListPodSandboxResponse> {
        fatalError("Not implemented yet")
    }

    func createContainer(
        request _: Runtime_V1_CreateContainerRequest,
        context _: any GRPC.StatusOnlyCallContext
    ) -> NIOCore.EventLoopFuture<Runtime_V1_CreateContainerResponse> {
        fatalError("Not implemented yet")
    }

    func startContainer(
        request _: Runtime_V1_StartContainerRequest,
        context _: any GRPC.StatusOnlyCallContext
    ) -> NIOCore.EventLoopFuture<Runtime_V1_StartContainerResponse> {
        fatalError("Not implemented yet")
    }

    func stopContainer(request _: Runtime_V1_StopContainerRequest, context _: any GRPC.StatusOnlyCallContext) -> NIOCore
        .EventLoopFuture<Runtime_V1_StopContainerResponse> {
        fatalError("Not implemented yet")
    }

    func removeContainer(
        request _: Runtime_V1_RemoveContainerRequest,
        context _: any GRPC.StatusOnlyCallContext
    ) -> NIOCore.EventLoopFuture<Runtime_V1_RemoveContainerResponse> {
        fatalError("Not implemented yet")
    }

    func listContainers(
        request _: Runtime_V1_ListContainersRequest,
        context _: any GRPC.StatusOnlyCallContext
    ) -> NIOCore.EventLoopFuture<Runtime_V1_ListContainersResponse> {
        fatalError("Not implemented yet")
    }

    func containerStatus(
        request _: Runtime_V1_ContainerStatusRequest,
        context _: any GRPC.StatusOnlyCallContext
    ) -> NIOCore.EventLoopFuture<Runtime_V1_ContainerStatusResponse> {
        fatalError("Not implemented yet")
    }

    func updateContainerResources(
        request _: Runtime_V1_UpdateContainerResourcesRequest,
        context _: any GRPC.StatusOnlyCallContext
    ) -> NIOCore.EventLoopFuture<Runtime_V1_UpdateContainerResourcesResponse> {
        fatalError("Not implemented yet")
    }

    func reopenContainerLog(
        request _: Runtime_V1_ReopenContainerLogRequest,
        context _: any GRPC.StatusOnlyCallContext
    ) -> NIOCore.EventLoopFuture<Runtime_V1_ReopenContainerLogResponse> {
        fatalError("Not implemented yet")
    }

    func execSync(request _: Runtime_V1_ExecSyncRequest, context _: any GRPC.StatusOnlyCallContext) -> NIOCore
        .EventLoopFuture<Runtime_V1_ExecSyncResponse> {
        fatalError("Not implemented yet")
    }

    func exec(request _: Runtime_V1_ExecRequest, context _: any GRPC.StatusOnlyCallContext) -> NIOCore
        .EventLoopFuture<Runtime_V1_ExecResponse> {
        fatalError("Not implemented yet")
    }

    func attach(request _: Runtime_V1_AttachRequest, context _: any GRPC.StatusOnlyCallContext) -> NIOCore
        .EventLoopFuture<Runtime_V1_AttachResponse> {
        fatalError("Not implemented yet")
    }

    func portForward(request _: Runtime_V1_PortForwardRequest, context _: any GRPC.StatusOnlyCallContext) -> NIOCore
        .EventLoopFuture<Runtime_V1_PortForwardResponse> {
        fatalError("Not implemented yet")
    }

    func containerStats(
        request _: Runtime_V1_ContainerStatsRequest,
        context _: any GRPC.StatusOnlyCallContext
    ) -> NIOCore.EventLoopFuture<Runtime_V1_ContainerStatsResponse> {
        fatalError("Not implemented yet")
    }

    func listContainerStats(
        request _: Runtime_V1_ListContainerStatsRequest,
        context _: any GRPC.StatusOnlyCallContext
    ) -> NIOCore.EventLoopFuture<Runtime_V1_ListContainerStatsResponse> {
        fatalError("Not implemented yet")
    }

    func podSandboxStats(
        request _: Runtime_V1_PodSandboxStatsRequest,
        context _: any GRPC.StatusOnlyCallContext
    ) -> NIOCore.EventLoopFuture<Runtime_V1_PodSandboxStatsResponse> {
        fatalError("Not implemented yet")
    }

    func listPodSandboxStats(
        request _: Runtime_V1_ListPodSandboxStatsRequest,
        context _: any GRPC.StatusOnlyCallContext
    ) -> NIOCore.EventLoopFuture<Runtime_V1_ListPodSandboxStatsResponse> {
        fatalError("Not implemented yet")
    }

    func updateRuntimeConfig(
        request _: Runtime_V1_UpdateRuntimeConfigRequest,
        context _: any GRPC.StatusOnlyCallContext
    ) -> NIOCore.EventLoopFuture<Runtime_V1_UpdateRuntimeConfigResponse> {
        fatalError("Not implemented yet")
    }

    func status(request _: Runtime_V1_StatusRequest, context _: any GRPC.StatusOnlyCallContext) -> NIOCore
        .EventLoopFuture<Runtime_V1_StatusResponse> {
        fatalError("Not implemented yet")
    }

    func checkpointContainer(
        request _: Runtime_V1_CheckpointContainerRequest,
        context _: any GRPC.StatusOnlyCallContext
    ) -> NIOCore.EventLoopFuture<Runtime_V1_CheckpointContainerResponse> {
        fatalError("Not implemented yet")
    }

    func getContainerEvents(
        request _: Runtime_V1_GetEventsRequest,
        context _: GRPC.StreamingResponseCallContext<Runtime_V1_ContainerEventResponse>
    ) -> NIOCore.EventLoopFuture<GRPC.GRPCStatus> {
        fatalError("Not implemented yet")
    }

    func listMetricDescriptors(
        request _: Runtime_V1_ListMetricDescriptorsRequest,
        context _: any GRPC.StatusOnlyCallContext
    ) -> NIOCore.EventLoopFuture<Runtime_V1_ListMetricDescriptorsResponse> {
        fatalError("Not implemented yet")
    }

    func listPodSandboxMetrics(
        request _: Runtime_V1_ListPodSandboxMetricsRequest,
        context _: any GRPC.StatusOnlyCallContext
    ) -> NIOCore.EventLoopFuture<Runtime_V1_ListPodSandboxMetricsResponse> {
        fatalError("Not implemented yet")
    }

    func runtimeConfig(request _: Runtime_V1_RuntimeConfigRequest, context _: any GRPC.StatusOnlyCallContext) -> NIOCore
        .EventLoopFuture<Runtime_V1_RuntimeConfigResponse> {
        fatalError("Not implemented yet")
    }
}
