using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;

public class LevelStatsDialog : BaseDialog {
    [SerializeField] private TextMeshProUGUI title;
    [SerializeField] private string titleText;

    [SerializeField] private Color activeColor = Color.white, inactiveColor = Color.gray;

    [Header("Record Labels")]
    [SerializeField] private TextMeshProUGUI normalLabel;
    [SerializeField] private TextMeshProUGUI perfectLabel;
    [SerializeField] private TextMeshProUGUI pearlLabel;
    [SerializeField] private TextMeshProUGUI pearlPerfectLabel;

    private Level level;

    public void Build(Level level) {
        this.level = level;
        Build();
    }

    public override void Build() {
        base.Build();
        title.text = string.Format(titleText, level.name);

        float nr = LevelUtils.GetRecord(level.id, LevelUtils.RecordType.normal);
        float pr = LevelUtils.GetRecord(level.id, LevelUtils.RecordType.perfect);
        float hr = LevelUtils.GetRecord(level.id, LevelUtils.RecordType.pearl);
        float hpr = LevelUtils.GetRecord(level.id, LevelUtils.RecordType.pearlPerfect);

        normalLabel.text = nr.ToTimeString();
        normalLabel.color = nr > 0 ? activeColor : inactiveColor;

        perfectLabel.text = pr.ToTimeString();
        perfectLabel.color = pr > 0 ? activeColor : inactiveColor;

        pearlLabel.text = hr.ToTimeString();
        pearlLabel.color = hr > 0 ? activeColor : inactiveColor;

        pearlPerfectLabel.text = hpr.ToTimeString();
        pearlPerfectLabel.color = hpr > 0 ? activeColor : inactiveColor;
    }
}
