using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEditorInternal;
using UnityEngine;

[CustomEditor(typeof(MeshEffectGroup))]
public class MeshEffectEditor : Editor {
    const int PROPS = 5;

    SerializedProperty meshes, gameObject;
    ReorderableList list;
    //public static int selected = -1;
    int row = 0;
    List<MeshCollider> collist = new List<MeshCollider>();

    private void OnEnable() {
        meshes = serializedObject.FindProperty("meshes");
        gameObject = serializedObject.FindProperty("m_GameObject");
        list = new ReorderableList(serializedObject, meshes, true, true, true, true);
        list.drawHeaderCallback = DrawHeader;
        list.drawElementCallback = DrawListItems;
        list.elementHeightCallback = ElementHeight;
    }

    public override void OnInspectorGUI() {
        serializedObject.Update();
        GetColliderList();

        list.DoLayoutList();

        //debug
        EditorGUILayout.IntField("Selected", MeshEffectGroup.editorSelected);

        serializedObject.ApplyModifiedProperties();
    }

    /*
    public void OnSceneGUI() {
        
        if (selected != -1 && Camera.current != null) {
            MeshEffectGroup mg = target as MeshEffectGroup;
            if (mg.meshes.Length <= selected) return;
            Mesh mesh = mg.meshes[selected].collider.sharedMesh;
        }
    }*/

    private void DrawHeader(Rect rect) {
        MeshEffectGroup.editorSelected = -1;
        EditorGUI.LabelField(rect, "Mesh Effects");
    }

    private void DrawListItems(Rect rect, int index, bool isActive, bool isFocused) {
        row = 0;
        SerializedProperty element = list.serializedProperty.GetArrayElementAtIndex(index);
        SerializedProperty col = element.FindPropertyRelative("collider");
        MeshCollider mc = (MeshCollider)col.objectReferenceValue;
        if (isActive) MeshEffectGroup.editorSelected = index;
        EditorGUI.PropertyField(PRect(rect), col, new GUIContent(string.Format("Collider [#{0} {1}]", GetColliderIndex(mc), GetColliderName(mc))), true);
        Row();

        EditorGUI.BeginDisabledGroup(mc == null);
        Rect mr = EditorGUI.PrefixLabel(PRect(rect), new GUIContent("    Mesh"));
        Mesh prevMesh = GetMesh(mc);
        Object changedMesh = EditorGUI.ObjectField(mr, prevMesh, typeof(Mesh), false);
        if(changedMesh != prevMesh && mc != null) {
            Undo.RecordObject(mc, "Changed Mesh");
            mc.sharedMesh = (Mesh)changedMesh;
        }
        Row();

        Rect cmr = EditorGUI.PrefixLabel(PRect(rect), new GUIContent("    Physics Material"));
        PhysicMaterial prevMaterial = GetPhysicMaterial(mc);
        Object changedMaterial = EditorGUI.ObjectField(cmr, prevMaterial, typeof(PhysicMaterial), false);
        if (changedMaterial != prevMaterial && mc != null) {
            Undo.RecordObject(mc, "Changed Physics Material");
            mc.sharedMaterial = (PhysicMaterial)changedMaterial;
        }
        Row();
        EditorGUI.EndDisabledGroup();

        EditorGUI.PropertyField(PRect(rect), element.FindPropertyRelative("hitFx"));
        Row();
        EditorGUI.PropertyField(PRect(rect), element.FindPropertyRelative("hitSound"));

        var enumerator = col.GetEnumerator();
        while (enumerator.MoveNext()) {
            var property = enumerator.Current as SerializedProperty;
            Debug.Log(property.name);
        }
    }

    private float ElementHeight(int index) {
        return EditorGUIUtility.singleLineHeight * PROPS;
    }

    private void Row() {
        row++;
    }

    private Rect PRect(Rect rect) {
        return new Rect(rect.x, rect.y + row * EditorGUIUtility.singleLineHeight, rect.width, EditorGUIUtility.singleLineHeight);
    }

    void GetColliderList() {
        GameObject go = gameObject.objectReferenceValue as GameObject;
        go.GetComponents(collist);
    }

    int GetColliderIndex(MeshCollider col) {
        if (col == null) return -1;
        return collist.IndexOf(col);
    }

    string GetColliderName(MeshCollider col) {
        if (col == null) return "Missing";
        return col.sharedMesh.name;
    }

    PhysicMaterial GetPhysicMaterial(MeshCollider col) {
        if (col == null) return null;
        return col.sharedMaterial;
    }

    Mesh GetMesh(MeshCollider col) {
        if (col == null) return null;
        return col.sharedMesh;
    }
}