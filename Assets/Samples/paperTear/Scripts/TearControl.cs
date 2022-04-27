using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TearControl : MonoBehaviour
{

    MeshRenderer meshRenderer;
    MeshFilter meshFilter;
    Mesh mesh;

    Vector3[] vertices;
    Vector3[] orginVertexs;

    List<Vector3> linePoints = new List<Vector3>{
        new Vector3(0,0,1),
        new Vector3(0,0,-1)
    };

    public AnimationCurve curve;

    [Range(0, 180f)]
    public float angle = 40f;
    [Range(-1, 1)]
    public float progress = 0;

    void Start()
    {
        meshFilter = GetComponent<MeshFilter>();
        mesh = meshFilter.mesh;
        orginVertexs = mesh.vertices;
    }

    void Update()
    {
        OnAngleSliderValueChanged(progress);
    }

    public void OnAngleSliderValueChanged(float value)
    {

        linePoints[0] = new Vector3(value, linePoints[0].y, linePoints[0].z);
        linePoints[1] = new Vector3(value, linePoints[1].y, linePoints[1].z);

        Vector3[] newVertexs = new Vector3[orginVertexs.Length];

        Vector3 lstart = linePoints[0];
        Vector3 lend = linePoints[1];
        //原点到折线的垂向量
        Vector3 offset = Point2LineVec(Vector3.zero, lstart, lend);
        Vector3 axis = (lend - lstart).normalized;

        for (int i = 0; i < orginVertexs.Length; i++)
        {
            if (IsVertexOnMarkLineRight(orginVertexs[i], lstart, lend))
            {
                Vector3 vtemp = new Vector3(orginVertexs[i].x,0,0);
                Vector3 vertexOffset = Point2LineVec(vtemp, lstart, lend);
                //将顶点先进行偏移
                Vector3 temp = orginVertexs[i] + offset;
                //旋转完后再将偏移恢复
                newVertexs[i] = Quaternion.AngleAxis(angle * Mathf.Abs(vertexOffset.x) * curve.Evaluate(angle / 180f), axis) * temp - offset;
            }
            else
            {
                newVertexs[i] = orginVertexs[i];
            }
        }

        mesh.vertices = newVertexs;
        mesh.RecalculateNormals();

    }

    //三维空间中，点到直线的垂向量
    //targetPoint:指定点 ；lstart,lend：直线上的两点
    private Vector3 Point2LineVec(Vector3 targetPoint, Vector3 lstart, Vector3 lend)
    {
        Vector3 p = targetPoint - lstart;
        Vector3 l = lend - lstart;
        //网格顶点在折线上的投影向量
        Vector3 projectVec = Vector3.Dot(p, l) * l.normalized + lstart;
        //点在折线上的垂向量d1A
        Vector3 p2lineVec = p - projectVec;
        return p2lineVec;
    }

    private bool IsVertexOnMarkLineRight(Vector3 vertex, Vector3 lstart, Vector3 lend)
    {
        Vector3 point2LineVec = Point2LineVec(vertex, lstart, lend);
        Vector3 lineVec = lend - lstart;
        return Vector3.Cross(lineVec, point2LineVec).y > 0;
    }

    private void OnDrawGizmos()
    {
        Gizmos.color = Color.red;
        if (linePoints.Count == 2)
        {
            Vector3 w1 = transform.TransformPoint(linePoints[0]);
            Vector3 w2 = transform.TransformPoint(linePoints[1]);
            Gizmos.DrawLine(w1, w2);
            Gizmos.DrawSphere(w1, 0.1f);
            Gizmos.DrawSphere(w2, 0.1f);
        }
    }

}
