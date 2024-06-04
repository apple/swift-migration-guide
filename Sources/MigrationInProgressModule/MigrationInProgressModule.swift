import FullyMigratedModule

func captureNonSendable(argument: ColorComponents) {
    Task {
        print(argument)
    }
}
