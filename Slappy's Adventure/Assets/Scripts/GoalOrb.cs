using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

using static LevelUtils;

public class GoalOrb : MonoBehaviour {
    //public string endScene = "EndScene", trueEndScene = "TrueEndScene";
    private bool ended = false;

    private void Awake() {
        ended = false;
    }

    private void OnCollisionEnter(Collision other) {
        if (ended) return;
        else if (other.gameObject.CompareTag("Sword")) {
            GameControl.Pause();
            ended = true;
            bool trueEnd = GameControl.main.player.gems >= GameControl.main.player.maxGems;

            AudioControl.main.music.FadeOut(1f, this);
            Level level = LevelData.Current().level;

            //time record
            Settings.TimeRecord = (float)NumberFrame.time;
            RecordType rtype = GetRecordType(trueEnd);
            TryUpdateRecord(Settings.TimeRecord, level.id, rtype);

            //level set
            SetCleared(level.id, true);
            TryUpdateGems(level.id, GameControl.main.player.gems);

            //note that this disposes LevelData
            EndingData.NewEndingData();

            UI.CircleFade(false, 2f, () => {
                Time.timeScale = 1f;
                SceneManager.LoadSceneAsync(trueEnd ? level.trueEndScene : level.endScene);
            });
        }
    }

    private RecordType GetRecordType(bool trueEnd) {
        if (GameControl.main.player.accessory.name == "TrialPearl") {
            if (trueEnd) return RecordType.pearlPerfect;
            return RecordType.pearl;
        }
        else {
            if (trueEnd) return RecordType.perfect;
            return RecordType.normal;
        }
    }
}
