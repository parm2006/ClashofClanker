global BuilderBaseLoopLogicLoaded := true

class BuilderBaseFlow {
    __New(primitives) {
        if !IsObject(primitives)
            throw Error("Builder Base flow primitives are required.")
        this.Primitives := primitives
        this.State := {
            side: 0,
            stageOneOutcome: "",
            stageTwoDeployed: false
        }
    }

    RunLoop() {
        while this.Primitives.Do("is_builder_running") {
            result := this.Attack()
            if (result == "stopped")
                break
            if (result == "home") {
                completion := this.Primitives.Do(
                    "complete_global_cycle",
                    "builder"
                )
                if (completion == "stopped")
                    break
            }
        }
        return true
    }

    Attack() {
        this.Primitives.Do("tap_builder_attack")
        this.Primitives.Do("tap_builder_find_match")
        if !this._Wait(4000)
            return "stopped"

        result := this.BeginAttack()
        if (result != "three_stars")
            return result

        if !this.DeployStageTwo()
            return "stopped"
        return this.MonitorStageTwo()
    }

    BeginAttack() {
        if !this.PrepareStageOne()
            return "stopped"
        this.State.stageOneOutcome := this.MonitorStageOne()
        return this.State.stageOneOutcome
    }

    PrepareStageOne() {
        this.State.stageOneOutcome := ""
        this.State.stageTwoDeployed := false
        if !this.Primitives.Do("prepare_builder_viewport")
            return false
        this.State.side := this.Primitives.Do("random_builder_side")
        return this.Primitives.Do("deploy_builder_troops", this.State.side)
    }

    MonitorStageOne() {
        completedChecks := 0
        Loop {
            if !this.Primitives.Do("is_builder_running")
                return "stopped"

            frame := this.Primitives.Do(
                "capture_builder_frame",
                "stage_one_stars"
            )
            if !this._IsValidFrame(frame) {
                ; ADB screencap is synchronous and normally takes about a
                ; second. Do not spin before issuing the next capture.
                if !this._Wait(1000)
                    return "stopped"
                continue
            }

            threeStars := this.Primitives.Do(
                "analyze_builder_three_stars",
                frame
            )
            completedChecks += 1
            this.Primitives.Do(
                "log",
                "Stage-one check " completedChecks "/4 completed."
            )
            if threeStars
                return "three_stars"

            if (completedChecks < 4) {
                if !this._Wait(1000)
                    return "stopped"
                continue
            }

            this.Primitives.Do(
                "log",
                "Stage-one check " completedChecks
                    ": attempting Return Home."
            )
            this.Primitives.Do("tap_return_home")
            homeResult := this._CheckHomeAfterReturn()
            if (homeResult == "stopped")
                return "stopped"
            if homeResult
                return "home"

            completedChecks := 0
            this.Primitives.Do(
                "log",
                "Stage-one check cycle reset to 0/4."
            )
            if !this._Wait(1000)
                return "stopped"
        }
    }

    DeployStageTwo() {
        if (this.State.stageOneOutcome != "three_stars")
            throw Error("Stage two requires a three-star stage-one outcome.")
        this.State.stageTwoDeployed := false
        if !this._Wait(15000)
            return false
        if !this.Primitives.Do("prepare_builder_viewport")
            return false
        deployed := this.Primitives.Do(
            "deploy_builder_troops",
            this.State.side
        )
        this.State.stageTwoDeployed := deployed
        return deployed
    }

    MonitorStageTwo() {
        if !this.State.stageTwoDeployed
            throw Error("Stage two must be deployed before monitoring.")
        Loop {
            if !this.Primitives.Do("is_builder_running") {
                this.State.stageTwoDeployed := false
                return "stopped"
            }
            if !this._Wait(15000) {
                this.State.stageTwoDeployed := false
                return "stopped"
            }

            this.Primitives.Do("tap_return_home")
            homeResult := this._CheckHomeAfterReturn()
            if (homeResult == "stopped") {
                this.State.stageTwoDeployed := false
                return "stopped"
            }
            if homeResult {
                this.State.stageTwoDeployed := false
                return "home"
            }
        }
    }

    _CheckHomeAfterReturn() {
        ; The battle-result transition takes longer than an ADB screencap.
        ; Do not mistake the just-dismissed battle screen for a failed return.
        if !this._Wait(2000)
            return "stopped"
        this.Primitives.Do("tap_return_home")
        if !this._Wait(2000)
            return "stopped"
        Loop {
            frame := this.Primitives.Do(
                "capture_builder_frame",
                "return_home"
            )
            if !this._IsValidFrame(frame) {
                if !this._Wait(1000)
                    return "stopped"
                continue
            }
            isBuilderBaseHome := this.Primitives.Do(
                "detect_builder_home_from_frame",
                frame
            )
            this.Primitives.Do(
                "log",
                isBuilderBaseHome
                    ? "Return Home home check: Builder Base detected."
                    : "Return Home home check: Builder Base not detected."
            )
            return isBuilderBaseHome
        }
    }

    _Wait(milliseconds) {
        return this.Primitives.Do("wait", milliseconds)
    }

    _IsValidFrame(frame) {
        if !IsObject(frame)
            return false
        return !frame.HasOwnProp("valid") || frame.valid
    }
}
