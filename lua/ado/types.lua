---@class RequestResult
---@field value any
--
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

---@class Comment
---@field id number
---@field commentType string
---@field content string

---@class CommentLinks
---@field self Link

---@class Link
---@field href string

---@class ThreadContext
---@field filePath string
---@field leftFileEnd Position|nil
---@field leftFileStart Position|nil
---@field rightFileEnd Position|nil
---@field rightFileStart Position|nil

---@class Position
---@field line number
---@field offset number
