debounce = (wait, func) ->
    return _.debounce(func, wait, {leading: true, trailing: false})


class LetsChatAdmin
    @.$inject = [
        "$rootScope",
        "$scope",
        "$tgRepo",
        "tgAppMetaService",
        "$tgConfirm",
        "$tgHttp",
    ]

    constructor: (@rootScope, @scope, @repo, @appMetaService, @confirm, @http) ->
        @scope.sectionName = "Let's Chat" #i18n
        @scope.sectionSlug = "letschat" #i18n

        @scope.$on "project:loaded", =>
            promise = @repo.queryMany("letschat", {project: @scope.projectId})

            promise.then (letschathooks) =>
                @scope.letschathook = {
                    project: @scope.projectId,
                    notify_userstory_create: true,
                    notify_userstory_change: true,
                    notify_userstory_delete: true,
                    notify_task_create: true,
                    notify_task_change: true,
                    notify_task_delete: true,
                    notify_issue_create: true,
                    notify_issue_change: true,
                    notify_issue_delete: true,
                    notify_wikipage_create: true,
                    notify_wikipage_change: true,
                    notify_wikipage_delete: true
                }
                if letschathooks.length > 0
                    @scope.letschathook = letschathooks[0]

                title = "#{@scope.sectionName} - Plugins - #{@scope.project.name}" # i18n
                description = @scope.project.description
                @appMetaService.setAll(title, description)

            promise.then null, =>
                @confirm.notify("error")

    testHook: () ->
        promise = @http.post(@repo.resolveUrlForModel(@scope.letschathook) + '/test')
        promise.success (_data, _status) =>
            @confirm.notify("success")
        promise.error (data, status) =>
            @confirm.notify("error")


LetsChatWebhooksDirective = ($repo, $confirm, $loading) ->
    link = ($scope, $el, $attrs) ->
        form = $el.find("form").checksley({"onlyOneErrorElement": true})
        submit = debounce 2000, (event) =>
            event.preventDefault()

            return if not form.validate()

            currentLoading = $loading()
                .target(submitButton)
                .start()

            if not $scope.letschathook.id
                promise = $repo.create("letschat", $scope.letschathook)
                promise.then (data) ->
                    $scope.letschathook = data
            else if $scope.letschathook.url
                promise = $repo.save($scope.letschathook)
                promise.then (data) ->
                    $scope.letschathook = data
            else
                promise = $repo.remove($scope.letschathook)
                promise.then (data) ->
                    $scope.letschathook = {
                        project: $scope.projectId,
                        notify_userstory_create: true,
                        notify_userstory_change: true,
                        notify_userstory_delete: true,
                        notify_task_create: true,
                        notify_task_change: true,
                        notify_task_delete: true,
                        notify_issue_create: true,
                        notify_issue_change: true,
                        notify_issue_delete: true,
                        notify_wikipage_create: true,
                        notify_wikipage_change: true,
                        notify_wikipage_delete: true
                    }

            promise.then (data)->
                currentLoading.finish()
                $confirm.notify("success")

            promise.then null, (data) ->
                currentLoading.finish()
                form.setErrors(data)
                if data._error_message
                    $confirm.notify("error", data._error_message)

        submitButton = $el.find(".submit-button")

        $el.on "submit", "form", submit
        $el.on "click", ".submit-button", submit

    return {link:link}


module = angular.module('taigaContrib.letschat', [])

module.controller("ContribLetsChatAdminController", LetsChatAdmin)
module.directive("contribLetschatWebhooks", ["$tgRepo", "$tgConfirm", "$tgLoading", LetsChatWebhooksDirective])

initLetsChatPlugin = ($tgUrls) ->
    $tgUrls.update({
        "letschat": "/letschat"
    })
module.run(["$tgUrls", initLetsChatPlugin])
