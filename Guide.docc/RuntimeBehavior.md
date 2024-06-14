# Runtime Behavior

Learn how Swift concurrency runtime semantics differ from other runtimes you may
be familiar with, and familiarize yourself with common patterns to achieve
similar end results in terms of execution semantics.

Swift's concurrency model with a strong focus on async/await, actors and tasks,
means that some patterns from other libraries or concurrency runtimes don't
translate directly into this new model. In this section, we'll explore common
patterns and differences in runtime behavior to be aware of, and how to address
them while you migrate your code to Swift concurrency.

## Limiting concurrency using Task Groups

Sometimes you may find yourself with a large list of work to be processed.

While it is possible to just enqueue "all" those work items to a task group like this:

```swift
// Potentially wasteful -- perhaps this creates thousands of tasks concurrently (?!)

let lotsOfWork: [Work] = ...
await withTaskGroup(of: Something.self) { group in
  for work in lotsOfWork {
    // If this is thousands of items, we may end up creating a lot of tasks here.
    group.addTask {
      await work.work()
    }
  }

  for await result in group {
    process(result) // process the result somehow, depends on your needs
  }
}
```

If you suspect you may be dealing with hundreds or thousands of items, it may be wasteful to enqueue them all immediately.
Creating a task (in `addTask`) needs to allocate some memory for the task in order to suspend and execute.
This amount of memory isn't too large, it can become significant if creating thousands of tasks which don't get to
execute immediately but are just waiting until the executor gets to run them.

When faced with such a situation, it may be beneficial to manually throttle the number of concurrently added tasks to the task group, as follows:

```swift
let lotsOfWork: [Work] = ... 
let maxConcurrentWorkTasks = min(lotsOfWork.count, 10)
assert(maxConcurrentWorkTasks > 0)

await withTaskGroup(of: Something.self) { group in
    var submittedWork = 0
    for _ in 0..<maxConcurrentWorkTasks {
        group.addTask { // or 'addTaskUnlessCancelled'
            await lotsOfWork[submittedWork].work() 
        }
        submittedWork += 1
    }
    
    for await result in group {
        process(result) // process the result somehow, depends on your needs
    
        // Every time we get a result back, check if there's more work we should submit and do so
        if submittedWork < lotsOfWork.count, 
           let remainingWorkItem = lotsOfWork[submittedWork] {
            group.addTask { // or 'addTaskUnlessCancelled'
                await remainingWorkItem.work() 
            }  
            submittedWork += 1
        }
    }
}
```
