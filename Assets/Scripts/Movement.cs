using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Movement : MonoBehaviour
{
    const float speed = 10.0f;
    const float slowSpeed = 1.0f;
    const float rotSpeed = 60.0f;

    void Update()
    {
        if (Input.GetKey("w"))
        {
            Vector3 dir = Vector3.forward;
            gameObject.transform.Translate(dir * speed * Time.deltaTime) ;
        }
        if (Input.GetKey("s"))
        {
            Vector3 dir = Vector3.forward * -1;
            gameObject.transform.Translate(dir * speed * Time.deltaTime);
        }
        if (Input.GetKey("d"))
        {
            Vector3 dir = Vector3.right;
            gameObject.transform.Translate(dir * speed * Time.deltaTime);
        }
        if (Input.GetKey("a"))
        {
            Vector3 dir = Vector3.right * -1;
            gameObject.transform.Translate(dir * speed * Time.deltaTime);
        }
        if (Input.GetKey("q"))
        {
            Vector3 dir = new Vector3(0, -1, 0);
            gameObject.transform.Rotate(dir * rotSpeed * Time.deltaTime);
        }
        if (Input.GetKey("e"))
        {
            Vector3 dir = new Vector3(0, 1, 0);
            gameObject.transform.Rotate(dir * rotSpeed * Time.deltaTime);
        }
        if (Input.GetKey(KeyCode.UpArrow))
        {
            Vector3 dir = Vector3.forward;
            gameObject.transform.Translate(dir * slowSpeed * Time.deltaTime);
        }
        if (Input.GetKey(KeyCode.DownArrow))
        {
            Vector3 dir = Vector3.forward *-1;
            gameObject.transform.Translate(dir * slowSpeed * Time.deltaTime);
        }
        if (Input.GetKey(KeyCode.RightArrow))
        {
            Vector3 dir = Vector3.right;
            gameObject.transform.Translate(dir * slowSpeed * Time.deltaTime);
        }
        if (Input.GetKey(KeyCode.LeftArrow))
        {
            Vector3 dir = Vector3.left;
            gameObject.transform.Translate(dir * slowSpeed * Time.deltaTime);
        }
    }
}
