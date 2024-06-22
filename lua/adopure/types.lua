---@class adopure.RequestResult
---@field value any


---@class adopure.PullRequest
---@field codeReviewid integer
---@field description string
---@field isDraft boolean
---@field pullRequestId boolean
---@field sourceRefName string
---@field targetRefName string
---@field title string
---@field url string
---@field status string
---@field createdBy adopure.User
---@field creationDate string
---@field mergeStatus string
---@field reviewers adopure.Reviewer[]

---@class adopure.User
---@field displayName string
---@field id string

---@class adopure.ConnectionUser
---@field id string
---@field isActive boolean

---@class adopure.ConnectionData
---@field authenticatedUser adopure.ConnectionUser
---@field authorizedUser adopure.ConnectionUser

---@class adopure.Reviewer
---@field displayName string
---@field id string
---@field vote PullRequestVote

---@class adopure.Repository
---@field name string
---@field id string
---@field url string
---@field defaultBranch string

---@class adopure.Project
---@field id string
---@field name string
---@field url string

---@class adopure.Thread
---@field id number
---@field comments adopure.Comment[]
---@field threadContext adopure.ThreadContext|nil
---@field status string
---@field isDeleted boolean
---@field publishedDate string
---@field lastUpdatedDate string

---@class adopure.Comment
---@field id number
---@field commentType string
---@field content string|nil
---@field author adopure.Author
---@field isDeleted boolean
---@field publishedDate string
---@field lastUpdatedDate string
---@field lastContentUpdatedDate string

---@class adopure.ThreadContext
---@field filePath string
---@field leftFileEnd adopure.Position|nil
---@field leftFileStart adopure.Position|nil
---@field rightFileEnd adopure.Position|nil
---@field rightFileStart adopure.Position|nil

---@class adopure.Position
---@field line number
---@field offset number

---@class adopure.Author
---@field id string
---@field displayName string

---@class adopure.CommentReply
---@field bufnr number
---@field mark_id number
---@field content string|nil
---@field thread adopure.Thread

---@class adopure.CommentCreate
---@field bufnr number
---@field mark_id number
---@field thread_context adopure.ThreadContext
---@field content string|nil

---@class adopure.NewThread
---@field comments adopure.NewComment[]
---@field threadContext adopure.ThreadContext
---@field pullRequestThreadContext  adopure.PullRequestCommentThreadContext
---@field status number

---@class adopure.NewComment
---@field parentCommentId number
---@field commentType number
---@field content string

---@class adopure.PullRequestCommentThreadContext
---@field changeTrackingId number
---@field iterationContext adopure.IterationContext
---@field trackingCriteria adopure.TrackingCriteria

---@class adopure.IterationContext
---@field firstComparingIteration number
---@field secondComparingIteration number

---@class adopure.TrackingCriteria
---@field firstComparingIteration number
---@field secondTrackingCriteria number

---@class adopure.Iteration
---@field id number
---@field sourceRefCommit adopure.CommitRef
---@field targetRefCommit adopure.CommitRef

---@class adopure.CommitRef
---@field commitId  string

---@class adopure.ChangeEntries
---@field changeEntries adopure.ChangeEntry[]

---@class adopure.ChangeEntry
---@field changeId number
---@field changeTrackingId number
---@field item adopure.ChangeEntryItem

---@class adopure.ChangeEntryItem
---@field path string
