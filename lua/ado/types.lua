---@class RequestResult
---@field value any


---@class PullRequest
---@field codeReviewid integer
---@field description string
---@field isDraft boolean
---@field pullRequestId boolean
---@field sourceRefName string
---@field targetRefName string
---@field title string
---@field url string
---@field status string
---@field createdBy User
---@field creationDate string
---@field mergeStatus string
---@field reviewers Reviewer[]

---@class User
---@field displayName string
---@field id string

---@class ConnectionUser
---@field id string
---@field isActive boolean

---@class ConnectionData
---@field authenticatedUser ConnectionUser
---@field authorizedUser ConnectionUser

---@class Reviewer
---@field displayName string
---@field id string
---@field vote PullRequestVote

---@class Repository
---@field name string
---@field id string
---@field url string
---@field defaultBranch string

---@class Project
---@field id string
---@field name string
---@field url string

---@class Thread
---@field id number
---@field comments Comment[]
---@field threadContext ThreadContext|nil
---@field status string
---@field isDeleted boolean
---@field publishedDate string
---@field lastUpdatedDate string

---@class Comment
---@field id number
---@field commentType string
---@field content string|nil
---@field author Author
---@field isDeleted boolean
---@field publishedDate string
---@field lastUpdatedDate string
---@field lastContentUpdatedDate string

---@class ThreadContext
---@field filePath string
---@field leftFileEnd Position|nil
---@field leftFileStart Position|nil
---@field rightFileEnd Position|nil
---@field rightFileStart Position|nil

---@class Position
---@field line number
---@field offset number

---@class Author
---@field id string
---@field displayName string

---@class CommentReply
---@field bufnr number
---@field mark_id number
---@field content string|nil
---@field thread Thread

---@class CommentCreate
---@field bufnr number
---@field mark_id number
---@field thread_context ThreadContext
---@field content string|nil

---@class NewThread
---@field comments NewComment[]
---@field threadContext ThreadContext
---@field pullRequestThreadContext  PullRequestCommentThreadContext
---@field status number

---@class NewComment
---@field parentCommentId number
---@field commentType number
---@field content string

---@class PullRequestCommentThreadContext
---@field changeTrackingId number
---@field iterationContext IterationContext
--@field trackingCriteria TrackingCriteria

---@class IterationContext
---@field firstComparingIteration number
---@field secondComparingIteration number

--@class TrackingCriteria
--@field firstComparingIteration number
--@field secondTrackingCriteria number

---@class Iteration
---@field id number
---@field sourceRefCommit CommitRef
---@field targetRefCommit CommitRef

---@class CommitRef
---@field commitId  string

---@class ChangeEntries
---@field changeEntries ChangeEntry[]

---@class ChangeEntry
---@field changeId number
---@field changeTrackingId number
---@field item ChangeEntryItem

---@class ChangeEntryItem
---@field path string
