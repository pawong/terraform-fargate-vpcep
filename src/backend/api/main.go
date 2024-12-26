package main

import (
	"fmt"
	"math/rand/v2"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
)

func main() {
	router := gin.Default()
	router.GET("/", readRoot)
	router.GET("/keepalive", keepAlive)

	router.GET("/8ball", getAnwserOnly)
	router.POST("/8ball", getAnwser)

	router.Run("0.0.0.0:80")
}

func readRoot(c *gin.Context) {
	c.IndentedJSON(http.StatusOK, gin.H{
		"hello":           "world",
		"GIT_COMMIT_HASH": fmt.Sprintf("%s", os.Getenv("GIT_COMMIT_HASH")),
	})
}

func keepAlive(c *gin.Context) {
	c.Data(http.StatusOK, "application/json; charset=utf-8", []byte("I'm alive!"))
}

var answers = [...]string{
	"It is certain",
	"It is decidedly so",
	"Without a doubt",
	"Yes definitely",
	"You may rely on it",
	"As I see it, yes",
	"Most likely",
	"Outlook good",
	"Yes",
	"Signs point to yes",
	"Reply hazy try again",
	"Ask again later",
	"Better not tell you now",
	"Cannot predict now",
	"Concentrate and ask again",
	"Don't count on it",
	"My reply is no",
	"My sources say no",
	"Outlook not so good",
	"Very doubtful",
}

type response struct {
	Question string `json:"question"`
	Answer   string `json:"answer"`
}

func getAnwserOnly(c *gin.Context) {
	c.Data(http.StatusOK, "application/json; charset=utf-8",
		[]byte(answers[rand.IntN(len(answers))]),
	)
}

func getAnwser(c *gin.Context) {
	var r response
	if err := c.BindJSON(&r); err != nil {
		return
	}
	r.Answer = answers[rand.IntN(len(answers))]
	c.IndentedJSON(http.StatusCreated, r)
}
